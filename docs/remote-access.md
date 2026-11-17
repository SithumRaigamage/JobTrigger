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
| **A2. WireGuard** | Yes | None (private VPN) | Same, when you want to run the VPN yourself |
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

## 3A. Option A2: WireGuard (step by step)

WireGuard is another private VPN: the phone gets a `10.x`/`172.x` address
that routes to the Mac from any network. Use it instead of Tailscale when you
want to host the VPN yourself. Nothing is opened to the internet.

### 3A.1 Set up the tunnel

1. Install WireGuard on the Mac (`brew install --cask wireguard`) and on the
   iPhone (App Store).
2. Pick a VPN subnet that does **not** overlap your home LAN, for example
   `10.9.0.0/24`. Generate a key pair for the server and one for the phone:

   ```bash
   wg genkey | tee server.key | wg pubkey > server.pub
   wg genkey | tee phone.key  | wg pubkey > phone.pub
   ```

3. Create `/etc/wireguard/wg0.conf` on the Mac (or use the WireGuard mac app
   to import the same settings). Replace the private keys and the public IP
   of your home router:

   ```ini
   [Interface]
   Address = 10.9.0.1/24
   ListenPort = 51820
   PrivateKey = <server.key>
   PostUp   = sysctl -w net.inet.ip.forwarding=1
   PostDown = sysctl -w net.inet.ip.forwarding=0

   [Peer]
   PublicKey = <phone.pub>
   AllowedIPs = 10.9.0.2/32
   ```

4. Forward UDP **51820** from your home router to the Mac, and start the
   interface: `sudo wg-quick up wg0` (or activate the tunnel in the mac app).
   A router port-forward here is for WireGuard's encrypted VPN only — do not
   forward the backend or Jenkins ports.

### 3A.2 Add the phone

1. In the iPhone WireGuard app, create a tunnel from a blank config:

   ```ini
   [Interface]
   Address = 10.9.0.2/32
   PrivateKey = <phone.key>
   DNS = 1.1.1.1

   [Peer]
   PublicKey = <server.pub>
   Endpoint = <home-router-public-ip>:51820
   AllowedIPs = 10.9.0.0/24, 192.168.1.0/24
   PersistentKeepalive = 25
   ```

   The second `AllowedIPs` entry lets the phone reach the Mac's **LAN**
   address as well as the VPN address, so an existing `192.168.x.x` backend
   keeps working. Change it to your actual LAN subnet.

2. Activate the tunnel, turn Wi-Fi off, and check in Safari that
   `http://10.9.0.1:5001/healthz` and `http://10.9.0.1:8080` answer (use
   `192.168.1.24` instead if you kept the LAN address).

### 3A.3 Point the app at it

1. Rebuild with the reachable address, e.g.
   `BACKEND_HOST=10.9.0.1 scripts/run-on-iphone.sh` (or the LAN IP if you
   routed that subnet in `AllowedIPs`).
2. Set the Jenkins server URL in the app to the same address and port, and
   set Manage Jenkins → System → Jenkins URL to match.
3. Keep the WireGuard tunnel on whenever you use the app away from home, and
   keep the Mac awake as in 3.6.

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

A tunnel gives the backend a public `https://` address without a router
port-forward. It is fine for a short demo; the address is public, so **do not
tunnel Jenkins** — use Tailscale or WireGuard for Jenkins.

### 5.1 Quick, random URL (try-it-now)

```bash
brew install cloudflare/cloudflare/cloudflared   # or download from Cloudflare
cloudflared tunnel --url http://localhost:5001
```

Copy the `https://<random>.trycloudflare.com` URL Cloudflare prints, then
rebuild with `BACKEND_BASE_URL=https://<random>.trycloudflare.com` in
`config/device.json`. The address changes every run, so you rebuild each
time. For a stable address, use a named tunnel.

### 5.2 Named tunnel (stable URL)

1. Sign in to Cloudflare and add your domain. In **Zero Trust → Networks →
   Tunnels**, create a tunnel and copy its token.
2. Install `cloudflared` (above) and run the `cloudflared service install
   <token>` command Cloudflare shows. It connects the Mac to Cloudflare on
   boot; no inbound ports are opened.
3. In the tunnel's **Public Hostname** settings add a hostname such as
   `jobtrigger.example.com` with service `HTTP` → `localhost:5001` (the
   backend's port). Cloudflare terminates TLS, so the app sees HTTPS.
4. Create `JobTrigger-Frontend/config/device.json` with
   `BACKEND_BASE_URL=https://jobtrigger.example.com` and rebuild with
   `scripts/run-on-iphone.sh`. Release builds require `https://`, so this is
   the only tunnel shape they accept.
5. Leave the `cloudflared` service and the Mac's backend running. If Safari
   on the phone can open the hostname, the app can reach it too.
6. Do **not** add a second public hostname for Jenkins. Keep Jenkins on
   Tailscale/WireGuard and edit its server URL in the app as in 3.4 / 3A.3.

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
| The app says the certificate isn't trusted | Self-signed cert, wrong hostname, or wrong device date/time | Check the date/time and the address; use a private VPN or a trusted certificate (5.2) |
| A `100.x.y.z` address won't connect | Tailscale off on the phone, or a different account | Turn Tailscale on and use the same account as the Mac |
| App closes at launch | `--release` build with an `http://` backend | Use `profile`, or deploy HTTPS (section 4) |
| App stops opening after a week | Free Apple ID 7-day limit | Reinstall with `scripts/run-on-iphone.sh` |
