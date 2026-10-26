// Direct calls to the fake backend (tests/e2e/fake-backend.mjs), to seed
// data for a test as the phone app would have saved it.
const BACKEND = "http://127.0.0.1:5999";

export async function backendToken(email: string, password: string): Promise<string> {
  const response = await fetch(`${BACKEND}/api/auth/login`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  return ((await response.json()) as { token: string }).token;
}

export async function seed(token: string, path: string, body: Record<string, unknown>) {
  const response = await fetch(`${BACKEND}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json", "x-auth-token": token },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`seed ${path} → ${response.status}`);
  return (await response.json()) as { _id: string };
}
