// A stand-in for JobTrigger-Backend in end-to-end tests: the same routes,
// validation, status codes and { message } bodies as the real controllers
// (JobTrigger-Backend/controllers), state in memory. Never a real backend.
// Tokens are JWT-shaped with a real `exp`, unsigned: only this server reads
// them, and the website never verifies them (src/server/jwt.ts).
import { randomUUID } from "node:crypto";
import { createServer } from "node:http";

const PORT = Number(process.env.FAKE_BACKEND_PORT ?? 5999);
const ACCESS_TTL_S = Number(process.env.FAKE_ACCESS_TTL_S ?? 900);
const REFRESH_TTL_S = 30 * 24 * 60 * 60;

/** Emails that make the login limiter answer 429, to test that path. */
const RATE_LIMITED = /^ratelimited/;

const users = new Map(); // email → { id, email, password, tokenVersion }
const credentials = { jenkins: [], github: [], sonarqube: [] };

const b64 = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
const token = (user, typ, ttl) =>
  `fake.${b64({ id: user.id, typ, tv: user.tokenVersion, exp: Math.floor(Date.now() / 1000) + ttl })}.sig`;
const issue = (user) => ({
  token: token(user, "access", ACCESS_TTL_S),
  refreshToken: token(user, "refresh", REFRESH_TTL_S),
  user: { _id: user.id, email: user.email },
});

function verify(value, typ) {
  try {
    const payload = JSON.parse(Buffer.from(String(value).split(".")[1], "base64url").toString());
    if (payload.typ !== typ || payload.exp * 1000 < Date.now()) return null;
    const user = [...users.values()].find((candidate) => candidate.id === payload.id);
    return user && user.tokenVersion === payload.tv ? user : null;
  } catch {
    return null;
  }
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const passwordProblem = (password) =>
  password.length < 8
    ? "Password must be at least 8 characters long"
    : Buffer.byteLength(password) > 72
      ? "Password is too long"
      : null;

const tools = {
  "/api/credentials": {
    kind: "jenkins",
    fields: ["serverName", "jenkinsURL", "username", "password", "paramToken"],
    required: ["serverName", "jenkinsURL", "username", "password"],
  },
  "/api/github-credentials": {
    kind: "github",
    fields: ["label", "token", "defaultOwner"],
    required: ["label", "token"],
  },
  "/api/sonarqube-credentials": {
    kind: "sonarqube",
    fields: ["label", "baseUrl", "token", "defaultOrganization"],
    required: ["label", "token"],
  },
};

function send(res, status, body, requestId) {
  res.writeHead(status, { "content-type": "application/json", "x-request-id": requestId });
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (chunks.length === 0) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString());
  } catch {
    return null;
  }
}

const server = createServer(async (req, res) => {
  const requestId = /^[A-Za-z0-9._-]{1,64}$/.test(req.headers["x-request-id"] ?? "")
    ? req.headers["x-request-id"]
    : randomUUID();
  const reply = (status, body) => send(res, status, body, requestId);
  const url = new URL(req.url, "http://fake");
  const body = await readBody(req);
  if (body === null) return reply(400, { message: "Malformed JSON body" });

  if (url.pathname === "/healthz") return reply(200, { status: "ok" });
  if (url.pathname === "/api/appinfo")
    return reply(200, { supportEmail: "support@jobtrigger.test", appVersion: "1.0.0" });

  // ---- auth ----
  if (url.pathname === "/api/auth/signup" && req.method === "POST") {
    const email = String(body.email ?? "")
      .trim()
      .toLowerCase();
    const password = String(body.password ?? "");
    if (!email || !password) return reply(400, { message: "Email and password are required" });
    if (!EMAIL.test(email)) return reply(400, { message: "Enter a valid email address" });
    const problem = passwordProblem(password);
    if (problem) return reply(400, { message: problem });
    if (users.has(email)) return reply(400, { message: "User already exists" });
    const user = {
      id: randomUUID().replaceAll("-", "").slice(0, 24),
      email,
      password,
      tokenVersion: 0,
    };
    users.set(email, user);
    return reply(201, issue(user));
  }
  if (url.pathname === "/api/auth/login" && req.method === "POST") {
    const email = String(body.email ?? "")
      .trim()
      .toLowerCase();
    if (RATE_LIMITED.test(email)) return reply(429, { message: "Too many attempts" });
    const user = users.get(email);
    if (!user || user.password !== body.password)
      return reply(400, { message: "Invalid credentials" });
    return reply(200, issue(user));
  }
  if (url.pathname === "/api/auth/refresh" && req.method === "POST") {
    const user = verify(body.refreshToken, "refresh");
    return user ? reply(200, issue(user)) : reply(401, { message: "Session expired" });
  }

  const user = verify(req.headers["x-auth-token"], "access");
  if (url.pathname.startsWith("/api/") && !user) {
    return reply(401, {
      message: req.headers["x-auth-token"]
        ? "Token is not valid"
        : "No token, authorization denied",
    });
  }

  if (url.pathname === "/api/auth/logout-all" && req.method === "POST") {
    user.tokenVersion += 1;
    return reply(200, { message: "Signed out everywhere" });
  }
  if (url.pathname === "/api/auth/password" && req.method === "POST") {
    const problem = passwordProblem(String(body.newPassword ?? ""));
    if (problem) return reply(400, { message: problem });
    if (body.currentPassword !== user.password)
      return reply(400, { message: "Current password is incorrect" });
    user.password = body.newPassword;
    user.tokenVersion += 1;
    return reply(200, issue(user));
  }
  if (url.pathname === "/api/auth/account" && req.method === "DELETE") {
    if (body.password !== user.password)
      return reply(400, { message: "Current password is incorrect" });
    for (const list of Object.values(credentials)) {
      for (let i = list.length - 1; i >= 0; i--) if (list[i].userId === user.id) list.splice(i, 1);
    }
    users.delete(user.email);
    return reply(200, { message: "Account deleted" });
  }

  // ---- credentials ----
  const [, , collection, first, second] = url.pathname.split("/");
  const tool = tools[`/api/${collection}`];
  if (tool) {
    const list = credentials[tool.kind];
    const mine = list.filter((row) => row.userId === user.id);
    const id = first === "switch" ? second : first;
    const row = id && mine.find((candidate) => candidate._id === id);
    const pick = () =>
      Object.fromEntries(tool.fields.filter((f) => body[f] !== undefined).map((f) => [f, body[f]]));
    const view = (r) => ({ ...r, needsReentry: false, __v: 0 });

    if (!id && req.method === "GET") return reply(200, mine.map(view));
    if (!id && req.method === "POST") {
      const values = pick();
      const missing = tool.required.filter((f) => !values[f]);
      if (missing.length)
        return reply(400, { message: "Invalid credential data", fields: missing });
      const created = {
        _id: randomUUID().replaceAll("-", "").slice(0, 24),
        userId: user.id,
        isDefault: false,
        ...values,
      };
      if (tool.kind === "sonarqube") created.baseUrl ??= "https://sonarcloud.io";
      list.push(created);
      if (body.isDefault === true)
        for (const r of mine.concat(created)) r.isDefault = r === created;
      return reply(201, view(created));
    }
    if (!row) return reply(404, { message: "Credential not found" });
    if (first === "switch" && req.method === "POST") {
      for (const r of mine) r.isDefault = r === row;
      return reply(200, view(row));
    }
    if (req.method === "PUT") {
      const values = pick();
      if (tool.required.some((f) => values[f] === ""))
        return reply(400, { message: "Invalid credential data", fields: [] });
      Object.assign(row, values);
      if (body.isDefault === true) for (const r of mine) r.isDefault = r === row;
      return reply(200, view(row));
    }
    if (req.method === "DELETE") {
      list.splice(list.indexOf(row), 1);
      return reply(200, { message: "Credential removed" });
    }
  }

  return reply(404, { message: "Not found" });
});

server.listen(PORT, "127.0.0.1", () => console.log(`fake backend on ${PORT}`));
