# Using JobTrigger away from your home Wi-Fi

Which networks can the iPhone app reach the backend and Jenkins on, and how
to make mobile data work. For the base iPhone setup, see
[`IPHONE.md`](../IPHONE.md).

## 1. What works today

| Phone is on | Works? | Why |
| --- | --- | --- |
| Same Wi-Fi as the Mac | Yes | The Mac's LAN address (e.g. `192.168.1.24`) is directly reachable. Needs the Mac awake and `./setup-dev.sh` running. |
| Mobile data, or any other Wi-Fi | **No** | `192.168.x.x` is a private address. It only exists on your home network. |
| Anywhere, app already installed | Partly | Only what needs no network (app lock, cached data). Login and Jenkins calls fail. |

The backend URL is fixed at **build time** (`BACKEND_BASE_URL`, read in
[`app_config.dart`](../JobTrigger-Frontend/lib/core/config/app_config.dart)).
Changing it means rebuilding the app. The Jenkins URL is different: it is
saved per server inside the app and can be edited there.

## 2. Options for mobile data

| Option | Needs the Mac on? | Public exposure | Good for |
| --- | --- | --- | --- |
| **A. Tailscale** (recommended) | Yes | None (private VPN) | Testing and daily use of your own Mac's backend and Jenkins |
| **B. Deploy the backend** | No (backend only) | HTTPS backend | TestFlight and real release builds |
| **C. Tunnel** (Cloudflare Tunnel, ngrok) | Yes | Public URL | Short demos only. Avoid for Jenkins. |

## 3. Option A: Tailscale (step by step)

Tailscale gives the Mac and the iPhone private addresses (`100.x.y.z`) that
work on any network, including mobile data. Nothing is opened to the
internet. It is free for personal use.

### 3.1 Install and sign in

1. Mac: install from <https://tailscale.com/download> (or
   `brew install --cask tailscale`) and sign in.
2. iPhone: install **Tailscale** from the App Store, sign in with the
   **same account**, and turn it **on**.
3. Get the Mac's Tailscale address:

   ```bash
   tailscale ip -4        # e.g. 100.101.102.103
   ```

   (If the CLI isn't found, copy the address from the Tailscale menu-bar app.)

### 3.2 Check the phone can reach the Mac

With Tailscale on and Wi-Fi **off** (mobile data), open Safari on the
iPhone:

- `http://<tailscale-ip>:5001/healthz` must answer (backend running).
- `http://<tailscale-ip>:8080` must show Jenkins (Jenkins published with
  `-p 8080:8080`, see IPHONE.md 5.1).

If Safari can't load them, the app can't either. See Troubleshooting.

### 3.3 Rebuild the app with the Tailscale address

```bash
BACKEND_HOST=100.101.102.103 scripts/run-on-iphone.sh
```

This writes `config/device.json` with
`BACKEND_BASE_URL=http://100.101.102.103:5001`, checks the backend answers
there, and installs a **profile** build.

> Use the `100.x.y.z` **IP address**, not the `*.ts.net` MagicDNS name. iOS
> App Transport Security blocks plain `http://` to named hosts but exempts
> IP addresses, which is also why your `192.168.x.x` address works today.

### 3.4 Point Jenkins at the Tailscale address

1. **Jenkins URL:** Manage Jenkins → System → Jenkins URL =
   `http://100.101.102.103:8080/` (so links Jenkins returns are reachable).
2. **In the app:** edit the saved Jenkins server and set its URL to
   `http://100.101.102.103:8080`.

### 3.5 Use it

Keep Tailscale on on the phone. The app now works on home Wi-Fi, mobile
data and other networks, as long as the Mac is awake, online, and running
the backend and Jenkins.

Tailscale's address stays the same when your home router or Wi-Fi changes,
so you don't repeat IPHONE.md section 6.

### 3.6 Keep the Mac reachable

- Stop it sleeping: System Settings → Battery/Energy → prevent automatic
  sleeping when the display is off, or run `caffeinate -s` in a terminal.
- Keep `./setup-dev.sh` and the Jenkins container running
  (`--restart unless-stopped` keeps Jenkins up across reboots).

## 4. Option B: deploy the backend

Use this when the app must work without your Mac, or for TestFlight.

1. Deploy `JobTrigger-Backend` to a host (Render, Railway, Fly, or your own
   server) following [`deployment.md`](deployment.md). It already uses
   MongoDB Atlas, so the database is reachable from the cloud.
2. Create `JobTrigger-Frontend/config/prod.json` with
   `ENVIRONMENT=prod` and `BACKEND_BASE_URL=https://<your-backend-host>`.
3. Build with `flutter run --release --dart-define-from-file=config/prod.json`
   (release builds **require** `https://`, AUD-43).
4. Jenkins is still called directly by the app, so it must also be
   reachable from the phone: put it behind HTTPS on a public host, or keep
   it on Tailscale and leave Tailscale on.

## 5. Option C: tunnel (not recommended)

`cloudflared tunnel --url http://localhost:5001` gives an `https://` URL
that forwards to your backend. It works for a quick demo, but the URL is
public and changes each run (unless you configure a named tunnel), so the
app must be rebuilt each time. Do **not** tunnel Jenkins: it would be
exposed to the internet.

## 6. Security notes

- Tailscale encrypts traffic between your devices, so `http://` over it is
  not readable by the mobile carrier or café Wi-Fi. The app still shows its
  `http://` warning, and release builds still refuse `http://`.
- Never publish Jenkins or the backend with a router port-forward. Use
  Tailscale or an HTTPS host.
- `config/device.json` holds your address and is git-ignored. Don't commit it.

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Works on Wi-Fi, fails on mobile data | App still built with the `192.168.x.x` address | Rebuild with `BACKEND_HOST=<tailscale-ip> scripts/run-on-iphone.sh` |
| Safari on mobile data can't open `:5001/healthz` | Tailscale off on the phone, different account, or Mac asleep | Turn Tailscale on; same account; wake the Mac |
| Backend works, Jenkins doesn't | Server URL in the app still uses the old address | Edit the server URL (3.4) |
| Jenkins links open `localhost` or the old IP | Jenkins URL not updated | 3.4 step 1 |
| Login fails with a named host (`*.ts.net`) | ATS blocks `http://` to hostnames | Use the `100.x.y.z` IP |
| App closes at launch | `--release` build with an `http://` backend | Use `profile`, or deploy HTTPS (section 4) |
| App stops opening after a week | Free Apple ID 7-day limit | Reinstall with `scripts/run-on-iphone.sh` |
