# Kismet + GPSD wardriving setup

A small Docker Compose setup for recording Wi-Fi observations with Kismet and
attaching GPS coordinates supplied by an Android phone. Kismon is an optional
GTK client for viewing observations while capturing.

Kismet does the capture and logging. GPSD receives NMEA data from the phone and
provides GPS readings to Kismet. This repository configures those programs; it
is not a Kismet fork.

## How it fits together

```text
Android phone (GPSd Forwarder)
    -- UDP/29998 --> host network --> GPSD
                                      <-- TCP/2947 (host loopback) -- Kismet
                                                                     |
                                                                     +-- data/kismet_logs/

Kismon (optional) -- http://127.0.0.1:2501 --> Kismet
```

| Service | Purpose | Notes |
| --- | --- | --- |
| `gpsd` | Receives the phone's GPS stream | UDP `29998` is published for the phone; TCP `2947` is exposed on host loopback only. |
| `kismet` | Captures Wi-Fi observations and serves the web UI | Uses host networking and elevated privileges to access the wireless adapter. |
| `kismon` | Optional GTK map and signal graphs | Starts with the `gui` profile and needs a working X11/Xwayland desktop session. |

## Requirements

- Linux with Docker Engine and the Docker Compose plugin.
- A Wi-Fi adapter supported by Linux/Kismet and capable of monitor mode.
- An Android phone with GPSd Forwarder installed from [F-Droid](https://f-droid.org/en/packages/io.github.tiagoshibata.gpsdclient/).
- A network path from the phone to the host. USB tethering is recommended for field use.
- For Kismon: an X11 or Xwayland desktop session.

## Set it up

### 1. Configure the host

Create your local environment file and the directories used for data:

```sh
cp env.example .env
chmod 600 .env
mkdir -p data/kismet_logs data/kismon_config
```

Edit `.env` before starting the stack. Set the interface and credentials; the
password in particular must not be left empty:

```sh
KISMET_INTERFACE=wlan0
KISMET_USER=admin
KISMET_PASSWORD=
KISMON_UID=1000
KISMON_GID=1000
```

Set `KISMET_INTERFACE` to the adapter you intend Kismet to capture with; find
its name with `iw dev` or `ip -br link`. Compose rejects an unset or empty
required Kismet setting. Set `KISMON_UID` and `KISMON_GID` to the numeric IDs
reported by `id -u` and `id -g` for your desktop user, so Kismon can write to
the host-mounted configuration directory. These values are used when building
the image; if you change them later, rebuild Kismon with
`docker compose --profile gui build kismon`.

`.env` is local configuration and is ignored by Git. Do not commit it or paste
its password into issue reports. The stack does not generate a replacement
password: the value you set is used by both Kismet and Kismon.

### 2. Connect GPSd Forwarder

The phone sends NMEA sentences to the **host's IP address** on UDP port
`29998`. Use an address that the phone can reach, not `127.0.0.1`.

**USB tethering (recommended):**

1. Connect the phone by USB and enable USB tethering in Android settings.
2. On the host, run `ip -br addr` and find the interface/address created for the
   tether connection (often `usb0`, `rndis*`, or `enx...`).
3. Open GPSd Forwarder and set that host IPv4 address as the destination, port
   `29998`, protocol `UDP`; start forwarding.

**Shared Wi-Fi:** connect the phone and host to the same Wi-Fi network or
hotspot. Use the host's IPv4 address on that network as the destination, with
UDP port `29998`.

The host's network manager normally handles address assignment. If the tether
interface has no address, diagnose that with the network manager already used
on this host; this project does not require a particular DHCP client or host
network configuration.

### Optional: `dhcpcd` hardening for field networks

If this host uses `dhcpcd` to configure USB-tethering or Wi-Fi client
interfaces, these profiles limit what those transient links can change on the
host. This is optional host-side wardriving hardening; it is not required by
Docker Compose and does not apply to interfaces managed by NetworkManager or
another network manager.

Add the applicable blocks to `/etc/dhcpcd.conf`. Adjust the patterns to match
`ip -br link`; prefer exact interface names if a broad pattern could match a
normal network interface. `usb*` may need to be `rndis*` or `enx*` on your host.

```text
# USB tethering (adjust the interface pattern for your host)
interface usb*
    anonymous
    randomise_hwaddr
    nohook resolv.conf
    nooption classless_static_routes

# Wi-Fi hotspot/client links (narrow wlan* if needed)
interface wlan*
    anonymous
    randomise_hwaddr
    nohook resolv.conf
    nooption classless_static_routes
    noarp
```

The profiles disable the `resolv.conf` hook and suppress classless static
routes from DHCP; they also request anonymous DHCP and a randomized hardware
address. The Wi-Fi profile's `noarp` additionally disables IPv4LL, so keep it
only if that is appropriate for the networks you use. Review the matching
interfaces before applying these settings: `wlan*` may include an interface
used for ordinary connectivity.

## Start and stop

**Start the full stack, including Kismon:**

```sh
docker compose --profile gui up --build -d
```

**Start capture without the GUI:**

```sh
docker compose up --build -d
```

Open <http://127.0.0.1:2501/> on the host and log in with `KISMET_USER` and
`KISMET_PASSWORD` from `.env`. The Kismet web service may also be reachable from
other hosts, depending on the host network and firewall; do not expose it to
the internet or an untrusted network.

To start or recreate Kismon during an active capture session:

```sh
docker compose --profile gui up -d kismon
```

To see service state and logs:

```sh
docker compose ps -a
docker compose logs --tail=100 kismet gpsd kismon
```

Stop the stack without deleting recordings or configuration:

```sh
docker compose down
```

Changing credentials in `.env` requires recreating Kismet and Kismon so the
containers receive the new environment values:

```sh
docker compose --profile gui up -d --force-recreate kismet kismon
```

## Check that GPS is arriving

A running container does not prove that the phone is forwarding data or that
the receiver has a valid satellite fix. Check in this order:

1. Confirm GPSd Forwarder is running and targets the host's reachable address
   on UDP `29998`.
2. Inspect `docker compose logs --tail=100 gpsd`.
3. Connect to GPSD from inside its container:

   ```sh
   docker compose exec gpsd gpsmon localhost:2947
   ```

4. Confirm GPSD is receiving data and has a fix. Then check that Kismet is
   healthy and configured to use `127.0.0.1:2947`.

## Where data and settings live

- **Recordings:** `data/kismet_logs/` on the host. Back this directory up;
  capture logs can contain location history and information about nearby
  devices.
- **Local settings and credentials:** `.env` on the host; ignored by Git.
- **Kismet configuration:** generated inside the container from `.env` when
  Kismet starts. Do not edit `/usr/local/etc/kismet_site.conf` expecting the
  change to survive a container restart.
- **Kismon configuration:** the host directory `data/kismon_config/` is mounted
  into the GUI container. Its entrypoint rewrites `kismon.conf` at startup from
  `.env`, so manual edits to that file are replaced on the next start.

## Troubleshooting

**Kismet cannot start or does not see the adapter**

- Check the interface name in `.env` with `iw dev` and `ip -br link`.
- Read `docker compose logs --tail=100 kismet` and `docker compose ps -a`.
- Confirm the adapter and driver support monitor mode. Other tools or network
  management may conflict with capture; do not blindly stop networking
  services on a host you depend on for connectivity.

**The web UI does not open or login fails**

- Check `docker compose ps -a` and `docker compose logs --tail=100 kismet`.
- Confirm Kismet is healthy, then try <http://127.0.0.1:2501/>.
- Verify the username and password in `.env`. After changing them, recreate
  both Kismet and Kismon as shown above; a plain restart does not refresh
  container environment variables.

**Kismon reports connection errors**

- Confirm Kismet is healthy and its local web UI responds first.
- Read `docker compose logs --tail=100 kismon`.
- Kismon's source revision is pinned, but its published compatibility list is
  old; successful image construction does not guarantee compatibility with the
  Kismet version in use.

**No GPS coordinates appear in Kismet**

- Recheck the phone's destination address and UDP port `29998`.
- Check GPSD's logs and use `gpsmon` as described above.
- Check host firewall rules and ensure another process is not occupying either
  GPSD port. Receiving NMEA data and having a valid GPS fix are separate things.

## Updating

The Kismet image is based on `finchsec/kismet:latest`, a mutable tag. Kismon
and `python-kismet-rest` revisions are pinned in `kismon/Dockerfile`. Before
updating, back up `data/kismet_logs/` and check whether Kismon works with the
Kismet version being pulled. The Kismon upstream README documents known
compatibility only through Kismet `2020-12-R3`, so treat the GUI as optional
until its REST connection has been verified.

To rebuild after changing a Dockerfile or deliberately updating the pinned
source revisions:

```sh
docker compose --profile gui up --build -d
```

To explicitly pull a newer base image before rebuilding:

```sh
docker compose --profile gui build --pull
docker compose --profile gui up -d
```

## Scope and authorization

Use this setup only where you are authorized to collect wireless observations
and follow local law and the rules of the networks you survey. Treat capture
files as sensitive data.
