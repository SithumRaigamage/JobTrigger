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

let secretFetches = 0;

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
  // Test-only: how many decrypted secrets were requested so far.
  if (url.pathname === "/__stats") return reply(200, { secretFetches });
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

  // P20-31/32: the plan. Billing is off unless the email says otherwise, so
  // every other spec sees no plan section.
  if (url.pathname === "/api/subscription" && req.method === "GET") {
    const free = user.email.startsWith("free-plan-");
    const pro = user.email.startsWith("pro-plan-");
    return reply(200, {
      plan: pro ? "pro" : "free",
      billingEnabled: free || pro,
      status: pro ? "active" : "none",
      source: pro ? "app_store" : null,
      productId: pro ? "pro_yearly" : null,
      periodEnd: pro ? "2027-03-03T10:00:00.000Z" : null,
      willRenew: pro,
      manageOnWeb: false,
      limits: pro
        ? { maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null }
        : { maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 },
      features: {
        multiTool: pro,
        backgroundWatch: pro,
        homeWidget: pro,
        insights: pro,
      },
      primaryCredentialId: null,
    });
  }

  // P20-83: web checkout. A made-up transaction; nothing talks to Paddle.
  if (url.pathname === "/api/billing/paddle/checkout" && req.method === "POST") {
    if (user.email.startsWith("pro-plan-"))
      return reply(409, { message: "Already subscribed", code: "ALREADY_SUBSCRIBED" });
    if (!["monthly", "yearly"].includes(body.interval))
      return reply(400, { message: "Choose monthly or yearly" });
    return reply(200, { transactionId: "txn_e2e_fake", environment: "sandbox" });
  }
  if (url.pathname === "/api/billing/paddle/portal" && req.method === "POST") {
    return reply(404, { message: "No web subscription" });
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
  // Re-checks the password and changes nothing (verify-password).
  if (url.pathname === "/api/auth/verify-password" && req.method === "POST") {
    return user.password === body.password
      ? reply(200, { message: "Password confirmed" })
      : reply(400, { message: "Current password is incorrect" });
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
    // E4: like the real backend, responses carry a mask and never a secret.
    const maskOf = (value) =>
      typeof value !== "string" || value === ""
        ? null
        : value.length >= 8
          ? `••••${value.slice(-4)}`
          : "••••";
    const view = (r) => {
      const { password, token, paramToken, ...rest } = r;
      return {
        ...rest,
        secretMask: maskOf(password ?? token),
        ...(tool.kind === "jenkins" ? { hasParamToken: Boolean(paramToken) } : {}),
        needsReentry: false,
        __v: 0,
      };
    };
    // The decrypted secret, owner only. Counted, so a spec can prove the
    // portal asked only after the password was confirmed.
    if (second === "secret") {
      secretFetches += 1;
      if (!row) return reply(404, { message: "Credential not found" });
      return reply(
        200,
        tool.kind === "jenkins"
          ? {
              password: row.password ?? null,
              paramToken: row.paramToken ?? null,
              needsReentry: false,
              version: "v1",
            }
          : { token: row.token ?? null, needsReentry: false, version: "v1" },
      );
    }

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

// FAKE_BACKEND_HOST=0.0.0.0 lets a container reach it (the Docker smoke test).
const HOST = process.env.FAKE_BACKEND_HOST ?? "127.0.0.1";
server.listen(PORT, HOST, () => console.log(`fake backend on ${HOST}:${PORT}`));
