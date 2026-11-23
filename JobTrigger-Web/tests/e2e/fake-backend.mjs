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

// Counted per account (the specs run in parallel), keyed by email.
const secretFetches = new Map();
// Requests for GitHub or SonarQube credentials, counted per account (the
// specs run in parallel), keyed by email. A spec reads these through /__stats.
const toolRequests = new Map();
// US-WEB-04: Support tickets filed per account (the website's tool request).
const tickets = new Map();
// Phase 31: the same tickets in one global list for the owner's review queue.
const allTickets = new Map();
// Phase 31: screenshot bytes keyed by `${ticketId}:${index}` (never in a list).
const supportShots = new Map();

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

// ---- Phase 21: student plan (the real rules are in the backend's
// studentController.js and adminStudentController.js) ----
const LISTED = /(^|\.)(ac\.lk|edu)$/;
const isAdmin = (user) => user.email.startsWith("student-admin-");
const applications = new Map(); // id → { id, userId, ... }
const documents = new Map(); // id → Buffer
const mimeOf = (bytes) =>
  bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff
    ? "image/jpeg"
    : bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
      ? "image/png"
      : bytes.subarray(0, 5).toString("latin1") === "%PDF-"
        ? "application/pdf"
        : null;
const YEAR_MS = 365 * 24 * 60 * 60 * 1000;
const publicApp = (a) => ({
  id: a.id,
  method: a.method,
  status: a.status,
  universityEmail: a.universityEmail ?? null,
  rejectionReason: a.rejectionReason ?? null,
  submittedAt: a.createdAt,
  approvedAt: a.approvedAt ?? null,
  expiresAt: a.expiresAt ?? null,
});
const adminApp = (a) => ({
  ...publicApp(a),
  userId: a.userId,
  accountEmail: [...users.values()].find((u) => u.id === a.userId)?.email ?? null,
  fullName: a.fullName ?? null,
  emailVerifiedAt: a.emailVerifiedAt ?? null,
  reviewedAt: a.reviewedAt ?? null,
  reviewedByEmail: a.reviewedByEmail ?? null,
  documentMime: a.method === "document" ? (a.mime ?? null) : null,
  documentSize: a.method === "document" ? (documents.get(a.id)?.length ?? null) : null,
  hasDocument: a.method === "document" && documents.has(a.id),
  documentDeleted: false,
  documentDeleteAt: a.documentDeleteAt ?? null,
});

// Phase 32: the same five fictional applicants as the backend's local seed
// script. They make the admin queue realistic and let the e2e specs approve
// and reject without signing up a student first. Test-only reset below.
const DEMO_PASSWORD = "DemoPass123!";
const DEMO_ID_BYTES = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.from("fictional demo student id"),
]);
const DEMO_PEOPLE = [
  {
    key: "d1",
    email: "demo-nimali@jobtrigger.app",
    method: "email",
    universityEmail: "nimali.silva@student.mtu.ac.lk",
    status: "pending",
    submittedDaysAgo: 2,
    verifiedDaysAgo: 2,
  },
  {
    key: "d2",
    email: "demo-kasun@jobtrigger.app",
    method: "document",
    fullName: "Kasun Perera",
    status: "pending",
    submittedDaysAgo: 5,
    document: true,
  },
  {
    key: "d3",
    email: "demo-anushka@jobtrigger.app",
    method: "email",
    universityEmail: "anushka.fernando@student.pdn.ac.lk",
    status: "approved",
    submittedDaysAgo: 50,
    verifiedDaysAgo: 50,
    approvedDaysAgo: 45,
  },
  {
    key: "d4",
    email: "demo-tharindu@jobtrigger.app",
    method: "document",
    fullName: "Tharindu Wickramasinghe",
    status: "rejected",
    submittedDaysAgo: 6,
    reviewedDaysAgo: 3,
    rejectionReason: "The photo is too blurry to read. Upload a clearer student ID.",
    document: true,
  },
  {
    key: "d5",
    email: "demo-maya@jobtrigger.app",
    method: "email",
    universityEmail: "maya.chandrasekaran@student.ruh.ac.lk",
    status: "expired",
    submittedDaysAgo: 400,
    verifiedDaysAgo: 400,
    approvedDaysAgo: 400,
  },
];

function seedDemoStudents() {
  const now = Date.now();
  const ago = (days) => new Date(now - days * 24 * 60 * 60 * 1000).toISOString();
  for (const person of DEMO_PEOPLE) {
    const suffix = person.key.padStart(21, "0");
    const id = `64c${suffix}`;
    const userId = `64d${suffix}`;
    users.delete(person.email);
    applications.delete(id);
    documents.delete(id);
    const reviewedAt =
      person.approvedDaysAgo != null
        ? ago(person.approvedDaysAgo)
        : person.reviewedDaysAgo != null
          ? ago(person.reviewedDaysAgo)
          : null;
    const approvedAt = person.approvedDaysAgo == null ? null : ago(person.approvedDaysAgo);
    const app = {
      id,
      userId,
      method: person.method,
      status: person.status,
      fullName: person.fullName ?? null,
      universityEmail: person.universityEmail ?? null,
      emailVerifiedAt: person.verifiedDaysAgo == null ? null : ago(person.verifiedDaysAgo),
      createdAt: ago(person.submittedDaysAgo),
      reviewedAt,
      reviewedByEmail: reviewedAt ? "student-admin@example.com" : null,
      approvedAt,
      expiresAt: approvedAt
        ? new Date(new Date(approvedAt).getTime() + YEAR_MS).toISOString()
        : null,
      rejectionReason: person.rejectionReason ?? null,
      mime: person.document ? "image/png" : null,
      documentDeleteAt:
        person.document && reviewedAt
          ? new Date(new Date(reviewedAt).getTime() + 30 * 24 * 60 * 60 * 1000).toISOString()
          : null,
    };
    applications.set(id, app);
    if (person.document) documents.set(id, DEMO_ID_BYTES);
    const user = { id: userId, email: person.email, password: DEMO_PASSWORD, tokenVersion: 0 };
    users.set(person.email, user);
    if (app.status === "approved") user.student = app;
  }
}
seedDemoStudents();

function student(url, req, body, user, reply) {
  const mine = () => [...applications.values()].filter((a) => a.userId === user.id).at(-1);
  if (url.pathname === "/api/student" && req.method === "GET") {
    const latest = mine();
    return reply(200, latest ? publicApp(latest) : { status: "none" });
  }
  const blocked = mine();
  if (blocked?.method === "document" && blocked.status === "pending")
    return reply(409, {
      code: "under_review",
      message: "Your student document is already waiting for review.",
    });
  if (url.pathname === "/api/student/email/start" && req.method === "POST") {
    const email = String(body.universityEmail ?? "")
      .trim()
      .toLowerCase();
    if (!EMAIL.test(email)) return reply(400, { message: "Enter a valid email address" });
    if (!LISTED.test(email.split("@")[1]))
      return reply(400, {
        code: "domain_not_listed",
        message:
          "We can't verify that email domain automatically. Upload a student ID or enrolment letter instead.",
      });
    user.pendingStudentEmail = email;
    return reply(202, { message: `We sent a code to ${email}.`, expiresInMinutes: 10 });
  }
  if (url.pathname === "/api/student/email/confirm" && req.method === "POST") {
    if (!user.pendingStudentEmail)
      return reply(400, { code: "no_code", message: "Ask for a new code first." });
    if (body.code !== "123456")
      return reply(400, { code: "wrong_code", message: "That code is not right. 4 tries left." });
    const now = new Date();
    const app = {
      id: randomUUID().replaceAll("-", "").slice(0, 24),
      userId: user.id,
      method: "email",
      status: "approved",
      universityEmail: user.pendingStudentEmail,
      createdAt: now.toISOString(),
      approvedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + YEAR_MS).toISOString(),
    };
    applications.set(app.id, app);
    user.student = app;
    return reply(200, publicApp(app));
  }
  if (url.pathname === "/api/student/document" && req.method === "POST") {
    const fullName = String(body.fullName ?? "").trim();
    if (fullName.length < 2)
      return reply(400, { message: "Enter your full name as it appears on your student ID" });
    const bytes = Buffer.from(String(body.data ?? ""), "base64");
    if (bytes.length > 5 * 1024 * 1024) return reply(413, { message: "File too large, max 5 MB" });
    const mime = mimeOf(bytes);
    if (!mime) return reply(415, { message: "Only JPG, PNG or PDF files are accepted" });
    const app = {
      id: randomUUID().replaceAll("-", "").slice(0, 24),
      userId: user.id,
      method: "document",
      status: "pending",
      fullName,
      mime,
      createdAt: new Date().toISOString(),
    };
    applications.set(app.id, app);
    documents.set(app.id, bytes);
    return reply(201, publicApp(app));
  }
  return reply(404, { message: "Not found" });
}

// Phase 31: an admin's view of one support ticket. The queue includes the
// screenshot count and triage fields but never bytes; detail adds only metadata.
function supportView(t, detail) {
  const view = {
    id: t.id,
    category: t.category,
    subject: t.subject,
    message: t.message,
    areas: t.areas,
    impact: t.impact,
    screenshotCount: t.screenshots.length,
    status: t.status,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    replyEmail: t.replyEmail ?? null,
    userEmail: t.userEmail ?? null,
    appVersion: null,
    buildNumber: null,
    tool: null,
    platform: null,
    serverHost: null,
  };
  if (detail) view.screenshots = t.screenshots;
  return view;
}

function adminSupport(url, req, body, user, reply, res) {
  // api admin support tickets [id] screenshots [index]
  const parts = url.pathname.split("/").filter(Boolean);
  if (parts[3] !== "tickets") return reply(404, { message: "Not found" });
  const id = parts[4];
  const action = parts[5];

  if (!id && req.method === "GET") {
    const status = url.searchParams.get("status") ?? "open";
    const tickets = [...allTickets.values()]
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .filter((t) => status === "all" || t.status === status)
      .map((t) => supportView(t, false));
    return reply(200, { tickets });
  }

  const ticket = allTickets.get(id);
  if (!ticket) return reply(404, { message: "Not found" });

  if (!action && req.method === "GET") return reply(200, { ticket: supportView(ticket, true) });

  if (!action && req.method === "PATCH") {
    if (!["open", "triaged", "closed"].includes(body.status))
      return reply(400, { message: "Choose a known status." });
    ticket.status = body.status;
    ticket.updatedAt = new Date().toISOString();
    return reply(200, { ticket: supportView(ticket, true) });
  }

  if (action === "screenshots" && req.method === "GET") {
    const shot = supportShots.get(`${id}:${parts[6]}`);
    if (!shot) return reply(404, { message: "Not found" });
    res.writeHead(200, { "content-type": shot.mime, "x-request-id": "e2e" });
    return res.end(shot.bytes);
  }
  return reply(404, { message: "Not found" });
}

function admin(url, req, body, user, reply, res) {
  // Everyone else gets the same 404 as an unknown route.
  if (!isAdmin(user)) return reply(404, { message: "Not found" });
  const parts = url.pathname.split("/").filter(Boolean); // api admin [support|students] ...
  if (parts[2] === "support") return adminSupport(url, req, body, user, reply, res);
  if (parts[2] !== "students") return reply(404, { message: "Not found" });
  const [, , , id, action] = parts;
  if (!id && req.method === "GET") {
    const status = url.searchParams.get("status") ?? "pending";
    const q = (url.searchParams.get("q") ?? "").toLowerCase();
    const items = [...applications.values()]
      .filter((a) => status === "all" || a.status === status)
      .map(adminApp)
      .filter(
        (a) =>
          !q ||
          (a.accountEmail ?? "").toLowerCase().includes(q) ||
          (a.fullName ?? "").toLowerCase().includes(q),
      );
    return reply(200, { items });
  }
  const app = applications.get(id);
  if (!app) return reply(404, { message: "Not found" });
  if (!action && req.method === "GET") return reply(200, adminApp(app));
  if (action === "document" && req.method === "GET") {
    if (app.method !== "document") return reply(404, { message: "Not found" });
    res.writeHead(200, { "content-type": app.mime, "x-request-id": "e2e" });
    return res.end(documents.get(app.id));
  }
  if (app.status !== "pending")
    return reply(409, { message: `This application is already ${app.status}.` });
  const now = new Date();
  if (action === "approve" && req.method === "POST") {
    app.status = "approved";
    app.approvedAt = now.toISOString();
    app.expiresAt = new Date(now.getTime() + YEAR_MS).toISOString();
    app.reviewedAt = now.toISOString();
    const owner = [...users.values()].find((u) => u.id === app.userId);
    if (owner) owner.student = app;
    return reply(200, adminApp(app));
  }
  if (action === "reject" && req.method === "POST") {
    const reason = String(body.reason ?? "").trim();
    if (!reason) return reply(400, { message: "Give a reason (up to 500 characters)" });
    app.status = "rejected";
    app.rejectionReason = reason;
    app.reviewedAt = now.toISOString();
    return reply(200, adminApp(app));
  }
  return reply(404, { message: "Not found" });
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
  if (url.pathname === "/__stats")
    return reply(200, {
      secretFetches: secretFetches.get(url.searchParams.get("email") ?? "") ?? 0,
      toolRequests: toolRequests.get(url.searchParams.get("email") ?? "") ?? 0,
      tickets: tickets.get(url.searchParams.get("email") ?? "") ?? [],
    });
  // Test-only: restore the five Phase 32 demo applications between specs.
  if (url.pathname === "/__reset-demo-students" && req.method === "POST") {
    seedDemoStudents();
    return reply(200, { status: "ok" });
  }
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

  // Phase 21: the student plan. Accounts named student-* have billing on and
  // are on Free; student-admin-* is a super admin. The code is always 123456.
  if (url.pathname.startsWith("/api/student")) return student(url, req, body, user, reply);
  if (url.pathname.startsWith("/api/admin/")) return admin(url, req, body, user, reply, res);

  // P20-31/32: the plan. Billing is off unless the email says otherwise, so
  // every other spec sees no plan section.
  if (url.pathname === "/api/subscription" && req.method === "GET") {
    const studentPro = user.student?.status === "approved";
    const free = user.email.startsWith("free-plan-") || user.email.startsWith("student-");
    const pro = user.email.startsWith("pro-plan-") || studentPro;
    return reply(200, {
      plan: pro ? "pro" : "free",
      billingEnabled: free || pro,
      status: pro ? "active" : "none",
      source: studentPro ? "student" : pro ? "app_store" : null,
      productId: pro && !studentPro ? "pro_yearly" : null,
      periodEnd: studentPro ? user.student.expiresAt : pro ? "2027-03-03T10:00:00.000Z" : null,
      willRenew: pro && !studentPro,
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
  // US-SUP-01/05/06 / US-WEB-04, with the backend's own copy.
  if (url.pathname === "/api/support/tickets" && req.method === "POST") {
    const categories = [
      "bug",
      "feature",
      "question",
      "tool_request",
      "account",
      "billing",
      "other",
    ];
    if (!categories.includes(body.category))
      return reply(400, { message: "Choose what kind of report this is." });
    if (!String(body.subject ?? "").trim())
      return reply(400, { message: "A subject is required." });
    if (!String(body.message ?? "").trim())
      return reply(400, { message: "Describe the issue or request." });
    const areas = Array.isArray(body.areas)
      ? body.areas.filter((area) => typeof area === "string")
      : [];
    const impact = ["blocked", "major", "minor"].includes(body.impact) ? body.impact : "minor";
    const shots = Array.isArray(body.screenshots) ? body.screenshots : [];
    if (shots.length > 3) return reply(413, { message: "Attach at most 3 screenshots." });
    const now = new Date().toISOString();
    const id = randomUUID().replaceAll("-", "").slice(0, 24);
    const screenshots = shots.map((shot, index) => {
      const bytes = Buffer.from(String(shot?.data ?? ""), "base64");
      const mime = mimeOf(bytes) ?? "image/png";
      supportShots.set(`${id}:${index}`, { bytes, mime });
      return {
        index,
        mime,
        size: bytes.length,
        hash: `e2e-${index}`,
        createdAt: now,
        deletedAt: null,
      };
    });
    const full = {
      id,
      category: body.category,
      subject: String(body.subject).trim(),
      message: String(body.message).trim(),
      areas,
      impact,
      replyEmail: body.replyEmail ?? user.email,
      userEmail: user.email,
      screenshots,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    allTickets.set(id, full);
    tickets.set(user.email, [
      ...(tickets.get(user.email) ?? []),
      { id, category: full.category, subject: full.subject },
    ]);
    return reply(201, { ticket: { id } });
  }
  if (url.pathname === "/api/billing/paddle/portal" && req.method === "POST") {
    return reply(404, { message: "No web subscription" });
  }

  if (/^\/api\/(github|sonarqube)-credentials/.test(url.pathname))
    toolRequests.set(user.email, (toolRequests.get(user.email) ?? 0) + 1);

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
      secretFetches.set(user.email, (secretFetches.get(user.email) ?? 0) + 1);
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
