# Tailscale

Tailscale gives remote access to the homelab apps from my own devices, without opening any port on the router. One container joins the tailnet as `homelab`, tagged `tag:homelab`, and publishes one [Tailscale Service](https://tailscale.com/kb/1552/tailscale-services) per app over HTTPS. Only my login can reach them. No Funnel, no subnet router.

|URL|backend|
|---|---|
|https://deye.tail3f2d79.ts.net|`host.docker.internal:18650` (deye-monitor, solarfarm stack)|
|https://plex.tail3f2d79.ts.net|`plex:32400`|
|https://jellyfin.tail3f2d79.ts.net|`jellyfin:8096`|
|https://torrent.tail3f2d79.ts.net|`qbittorrent:8080`|
|https://speedtest.tail3f2d79.ts.net|`speedtest:80`|
|https://ollama.tail3f2d79.ts.net|`ollama:11434`|
|`rdp.tail3f2d79.ts.net:3389` (plain TCP)|`host.docker.internal:3389` (Windows Remote Desktop)|

The routes live in `serve.json`, which the container watches and re-applies on change. It is a single-file bind mount, so edit it in place (an editor that saves in place, or `cat new > serve.json`). Tools that replace the file, such as `sed -i`, leave the container on the old copy; recover with `docker compose up -d --force-recreate --no-deps tailscale` (a plain restart fails). **After a recreate, check `docker exec tailscale tailscale debug prefs | grep -A7 AdvertiseServices`.** On 2026-09-30 it came back `null`: the Services had no host and every URL was dead. Run the manual advertise loop in step 8; the setting persists in `data/state/`. The container runs in userspace mode, keeps its state in `./data/state/` and reads the auth key from `./secrets/ts_authkey`. Both folders are git-ignored.

The image is pinned to `v1.102.5`. From 1.96 the container advertises the Services in `serve.json` by itself (`TS_EXPERIMENTAL_SERVICE_AUTO_ADVERTISEMENT`, default on). Older images, such as 1.92.2, needed a manual `tailscale serve advertise` ([#18255](https://github.com/tailscale/tailscale/issues/18255)).

## Setup

- [x] 1. Create the Tailscale account (tailnet `tail3f2d79.ts.net`, owner `ljivanov@gmail.com`).
- [x] 2. DNS: MagicDNS on, HTTPS certificates on.
- [x] 3. Phone `lyubos-s23` on the tailnet.
- [x] 4. Access policy (admin console, **Access controls**, JSON editor). Replace the whole file with the policy below. It removes the default allow-all.
- [x] 5. Define the 7 Services (admin console, **Services**).
- [x] 6. Generate the auth key and write it to `secrets/ts_authkey`.
- [x] 7. Windows: never sleep, auto sign-in, Docker Desktop at login.
- [x] 8. Start the container, check the node and the Services.
- [x] 9. Plex: add the custom server access URL.
- [ ] 10. Verify each service from the phone.

### 4. Access policy

```json
{
  "tagOwners": {
    "tag:homelab": ["autogroup:admin"]
  },

  "autoApprovers": {
    "services": {
      "svc:deye":      ["tag:homelab"],
      "svc:plex":      ["tag:homelab"],
      "svc:jellyfin":  ["tag:homelab"],
      "svc:torrent":   ["tag:homelab"],
      "svc:speedtest": ["tag:homelab"],
      "svc:ollama":    ["tag:homelab"],
      "svc:rdp":       ["tag:homelab"]
    }
  },

  "grants": [
    {
      "src": ["ljivanov@gmail.com"],
      "dst": ["svc:deye", "svc:plex", "svc:jellyfin", "svc:torrent", "svc:speedtest"],
      "ip":  ["tcp:443"]
    },
    {
      "src": ["ljivanov@gmail.com"],
      "dst": ["svc:ollama"],
      "ip":  ["tcp:443"]
    },
    {
      "src": ["ljivanov@gmail.com"],
      "dst": ["svc:rdp"],
      "ip":  ["tcp:3389"]
    },
    {
      "src": ["ljivanov@gmail.com"],
      "dst": ["tag:homelab"],
      "ip":  ["tcp:443"]
    }
  ],

  "ssh": []
}
```

- Only `ljivanov@gmail.com` can reach the Services, and only on 443 (3389 for rdp). ollama and rdp have their own grants so each can be dropped on its own.
- `tag:homelab` gets no grant as a source, so the homelab node cannot open connections to my devices.
- The third grant (my devices to `tag:homelab` on 443) is needed so my devices receive the `homelab` node as a peer; without it the phone could not route to the Services (ERR_CONNECTION_ABORTED). The node itself serves nothing on its own address.
- There is no `funnel` node attribute, so Funnel cannot be turned on by accident.
- My own devices cannot reach each other with this policy. If I want that later, add `{"src": ["ljivanov@gmail.com"], "dst": ["ljivanov@gmail.com"], "ip": ["*"]}`.

### 5. Services

Admin console, **Services**, **Define a Service**, once per name:

|name|port|
|---|---|
|`deye`|`tcp:443`|
|`plex`|`tcp:443`|
|`jellyfin`|`tcp:443`|
|`torrent`|`tcp:443`|
|`speedtest`|`tcp:443`|
|`ollama`|`tcp:443`|
|`rdp`|`tcp:3389`|

The names must match `serve.json` (`svc:<name>`). The `autoApprovers` above approve `homelab` as the host of each one, so no manual approval is needed after the node joins.

### 6. Auth key

Admin console, **Settings**, **Keys**, **Generate auth key**:

- Reusable: **off** (one-off)
- Expiration: **1 day**
- Ephemeral: **off**
- Pre-approved: **on**
- Tags: **on**, `tag:homelab`

Write it straight into the file, from bash in WSL (paste the key at the silent prompt, then Enter):

```bash
cd /home/livanov/programming/homelab/tailscale && mkdir -p secrets && (umask 077; read -rs -p 'Auth key: ' k && printf '%s\n' "$k" > secrets/ts_authkey; unset k); echo; chmod 600 secrets/ts_authkey
```

The key is spent at the first login (`TS_AUTH_ONCE`). After that the node lives on the saved state in `data/state/`, and the file is no longer needed.

**Key expiry.** A node that joins with a tag has key expiry disabled by default. Check it after step 8: admin console, **Machines**, `homelab` should show "Expiry disabled". If it doesn't: the `...` menu on the `homelab` row, **Disable key expiry**.

### 7. Windows

Docker Desktop hangs or a sleeping PC take every URL down, and there is no remote way back in.

- **Never sleep:** Settings, System, Power, Screen and sleep: "When plugged in, put my device to sleep after" **Never**.
- **Auto sign-in** after reboots and updates: run `netplwiz`, untick "Users must enter a user name and password to use this computer" (if the box is missing, set `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device\DevicePasswordLessBuildVersion` to `0` first). Also Settings, Accounts, Sign-in options: "Use my sign-in info to automatically finish setting up after an update" **on**.
- **Docker Desktop at login:** Docker Desktop, Settings, General: "Start Docker Desktop when you sign in to your computer" **on**.

### 8. Start

From the homelab folder, start only this container. No other container is touched.

```bash
docker compose up -d tailscale
docker logs -f tailscale                       # wait for "Startup complete" and the serve config being applied
docker exec tailscale tailscale status         # homelab online, tagged; the phone listed (direct or relay)
docker exec tailscale tailscale serve status   # the 7 Services and their backends
```

In the admin console, **Services**: each Service lists `homelab` as an approved host.

If a Service shows no host, advertise it by hand (the 1.92.2 bug should not apply to this version, but this is the fix if it does):

```bash
for s in deye plex jellyfin torrent speedtest ollama rdp; do docker exec tailscale tailscale serve advertise svc:$s; done
```

### 9. Plex

The tailnet URL goes in `PLEX_CUSTOM_CONNECTIONS` in the root `.env`, next to the LAN ones. Plex applies it at container start ("Custom server access URLs" in Plex Web), so a change there is lost on the next restart:

```
PLEX_CUSTOM_CONNECTIONS=http://plex.lan:80,http://10.0.0.11:32400,https://plex.tail3f2d79.ts.net:443
```

Plex treats tailnet requests as LAN (they come from the Tailscale container's 172.18.x address), but remote playback in the Plex apps may still ask for Plex Pass. Jellyfin has no such limit.

### 10. Verify from the phone

The first visit to each name fetches its HTTPS certificate (about 30–40 s) and can time out in the browser; retry. All six certificates were pre-fetched on 2026-09-27 with `docker exec tailscale tailscale cert <name>.tail3f2d79.ts.net`.

Turn **Wi-Fi off** on `lyubos-s23` (mobile data only), Tailscale connected. Each URL must open with a valid certificate:

- https://deye.tail3f2d79.ts.net: the dashboard loads, and acknowledging an event works.
- https://plex.tail3f2d79.ts.net: Plex Web loads and browses; try playing something.
- https://jellyfin.tail3f2d79.ts.net: login and playback work.
- https://torrent.tail3f2d79.ts.net: the qBittorrent WebUI loads.
- https://speedtest.tail3f2d79.ts.net: the page loads with its styles (no mixed-content errors). If it looks unstyled, set `APP_URL`/`ASSET_URL` in `speedtest/docker-compose.yaml`.
- https://ollama.tail3f2d79.ts.net/api/tags: returns the model list as JSON.
- Remote Desktop to `rdp.tail3f2d79.ts.net`: the Windows sign-in prompt appears. RDP travels as TCP only (no UDP transport), and the connection dies with Docker Desktop.

With Tailscale disconnected on the phone, none of the names resolve.

## Rollback

```bash
docker compose stop tailscale && docker compose rm -f tailscale
```

Then remove the `tailscale:` entry from the root `docker-compose.yaml` and this folder. In the admin console, delete the `homelab` machine and the 7 Services, and revoke any unused auth key. No app depends on Tailscale; the `*.lan` names keep working throughout.
