# Run JobTrigger on your iPhone

Test the app on a real iPhone while the **backend** and **Jenkins** run on
your Mac. About 20 minutes the first time; after that it's one command.

```text
 iPhone ──Wi-Fi──▶ Mac (e.g. 192.168.1.24)
                     ├─ :5001  backend  ──▶ MongoDB Atlas (cloud)
                     └─ :8080  Jenkins  (Docker)
```

**The one rule:** on the phone, `127.0.0.1` and `localhost` mean *the
phone itself*. Everything the phone opens — the backend, Jenkins — must use
your Mac's Wi-Fi address instead. The script in step 3 handles the backend;
step 5 covers Jenkins.

## What you need

- iPhone and Mac on the **same Wi-Fi**.
- A USB cable for the first install.
- The backend set up once: [`docs/mongodb-cloud-setup.md`](docs/mongodb-cloud-setup.md)
  (Atlas) and [`docs/dev-setup.md`](docs/dev-setup.md).
- Xcode signed in to the Apple ID for team `QRCA2Z2HYQ` (step 1).

## 1. Prepare the iPhone and Xcode (once)

1. Connect the iPhone by cable, unlock it and tap **Trust This Computer**.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode → On**
   (the phone restarts).
3. Open the project in Xcode:

   ```bash
   open JobTrigger-Frontend/ios/Runner.xcworkspace
   ```

   - **Xcode → Settings → Accounts**: sign in with the Apple ID for team
     `QRCA2Z2HYQ`.
   - **Signing & Capabilities**: the **Runner** and **PinnedJobsWidget**
     targets both show that team with no errors.
   - A free (personal) Apple ID usually can't sign the **App Groups**
     capability the home-screen widget uses. Use the paid team, or
     temporarily remove the widget target to test the rest of the app.

## 2. Start the backend

In a terminal at the repository root:

```bash
./setup-dev.sh
```

Leave it running. It listens on every network interface, so the phone can
reach it — no backend change needed.

## 3. Install the app on the iPhone

In a **second** terminal at the repository root:

```bash
scripts/run-on-iphone.sh
```

It:

1. finds your Mac's current Wi-Fi address (e.g. `192.168.1.24`);
2. writes `JobTrigger-Frontend/config/device.json` with
   `BACKEND_BASE_URL = http://<that address>:5001` (git-ignored: the
   address belongs to your network);
3. checks the backend answers at that address (`/healthz`), so you learn
   now, not inside the app;
4. finds the connected iPhone and runs `flutter run --profile` on it.

A **profile** build keeps working from the home screen after you unplug the
cable. Want hot reload while plugged in? `MODE=debug scripts/run-on-iphone.sh`.

**Configure anything the script guesses:**

| Variable | Default | Example |
| --- | --- | --- |
| `BACKEND_HOST` | The Mac's Wi-Fi IP | `BACKEND_HOST=192.168.1.50` |
| `BACKEND_PORT` | `5001` | `BACKEND_PORT=5002` |
| `DEVICE` | The one connected iPhone | `DEVICE="Sithum's iPhone"` (see `flutter devices`) |
| `MODE` | `profile` | `MODE=debug` |
| `SKIP_BACKEND_CHECK` | off | `SKIP_BACKEND_CHECK=1` |

`scripts/run-on-iphone.sh --config-only` just writes `device.json`, if you'd
rather run `flutter` yourself:

```bash
cd JobTrigger-Frontend
flutter run --profile --dart-define-from-file=config/device.json -d "<iPhone>"
```

> **Not `--release`.** A release build refuses an `http://` backend on
> purpose (AUD-43) and stops at launch. Release builds wait for the backend
> to be deployed on `https://` ([`docs/deployment.md`](docs/deployment.md)).

## 4. First launch on the phone

- **"Untrusted Developer"**: **Settings → General → VPN & Device
  Management** → your developer profile → **Trust**.
- **"Find devices on your local network"**: tap **Allow**. Without it the
  app can't reach your Mac. Missed it? **Settings → Privacy & Security →
  Local Network → JobTrigger → On**.
- Log in with the dev account `developer@jobtrigger.app` /
  `SecurePassword123!` (seeded by `setup-dev.sh`), or your own.

## 5. Jenkins on your Mac, reachable from the phone

The phone talks to Jenkins **directly**; the backend only stores its
address. Two things must be true: Jenkins listens on the network, and the
app has its network address saved.

### 5.1 Run Jenkins in Docker, published to the network

```bash
docker run -d --name jenkins \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  --restart unless-stopped \
  jenkins/jenkins:lts-jdk21
```

- **`-p 8080:8080`** is the important part: every network interface. With
  `-p 127.0.0.1:8080:8080` only the Mac itself can connect. In a Compose
  file: `ports: ["8080:8080"]`.
- `jenkins_home` keeps jobs and settings when the container is recreated.
- First start: `docker logs jenkins` prints the initial admin password.
  Keep Jenkins's login on.

The repository's test Jenkins (`tools/jenkins-fixture/`, port 8090) stays
localhost-only on purpose; use your own Jenkins for the phone.

### 5.2 Check from the phone

In the iPhone's **Safari**, open `http://<Mac IP>:8080`. The Jenkins page
must load. If Safari can't, the app can't either (see Troubleshooting).

### 5.3 Tell Jenkins its own address

**Manage Jenkins → System → Jenkins URL** = `http://<Mac IP>:8080/`.
Jenkins puts this address in the links it returns (builds, consoles); left
as `localhost`, they would point at the phone.

### 5.4 Add the server in the app

In the app, add a Jenkins server:

- **URL:** `http://<Mac IP>:8080` — never `localhost` or `127.0.0.1`
- **Username** and an **API token** (Jenkins → your name → **Security** →
  **API Token → Add new token**)

The app warns that `http://` sends credentials unencrypted. On your home
Wi-Fi that's expected.

## 6. When your Mac's address changes

Router restarts and different networks change the Mac's IP. Then:

1. Run `scripts/run-on-iphone.sh` again: it detects the new address and
   rebuilds the app with it.
2. Update **Jenkins URL** (5.3) and edit the saved server in the app (5.4).

Check the current address any time with `ipconfig getifaddr en0`.

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Script: "No Wi-Fi address found" | The Mac isn't on Wi-Fi (or uses another interface) | Join the Wi-Fi, or `BACKEND_HOST=<IP> scripts/run-on-iphone.sh` |
| Script: "The backend doesn't answer" | Backend not started, or crashed | `./setup-dev.sh` in another terminal; read its last line |
| Script: "No iPhone found" | Locked, untrusted, or Developer Mode off | Step 1; then `flutter devices` should list it |
| App: can't connect / login spins | Phone on another Wi-Fi (or mobile data), Local Network off, or the IP changed | Same Wi-Fi; step 4; step 6 |
| Safari on the phone can't open `http://<Mac IP>:5001/healthz` | The phone can't reach the Mac at all | Same Wi-Fi; some guest and office networks block devices from seeing each other — use a home network or the iPhone's hotspot for the Mac |
| Safari can't open Jenkins (`:8080`) | Published to `127.0.0.1` only, or not running | 5.1 (`-p 8080:8080`); `docker ps` |
| Jenkins links in the app point to `localhost` | Jenkins URL not set | 5.3 |
| App closes at launch | A `--release` build with an `http://` backend | Use `profile` or `debug` (step 3) |
| macOS asks "accept incoming connections?" for `node` or Docker | The macOS firewall is on | **Allow** |

## Security notes

- Publishing Jenkins on `8080` lets every device on the same Wi-Fi reach it.
  Fine at home with Jenkins's login on; on café or shared Wi-Fi, stop it or
  publish it as `127.0.0.1:8080:8080`.
- `http://` is for your own network only. Anything beyond it waits for the
  `https://` deployment.
- `config/device.json` holds your network address and is git-ignored.
  Don't commit it.
