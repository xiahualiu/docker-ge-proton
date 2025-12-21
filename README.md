# docker-ge-proton

A minimal Ubuntu-based Docker image that configures SteamCMD and GE-Proton for running Windows-only dedicated game servers on Linux.

## Features

- **Ubuntu 24.04** base image.
- **SteamCMD** pre-installed for downloading game servers.
- **GE-Proton** for Windows compatibility layer.
- **Xvfb** virtual framebuffer for headless operation.
- Non-root user setup for security.
- Volume support for persistent game data.

## Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/xiahualiu/docker-ge-proton.git
   cd docker-ge-proton
   ```

2. Customize `compose.yaml` for your game (see [Configuration](#configuration))

3. Start the server:

   ```bash
   docker compose up -d
   ```

## Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `STEAM_APP_ID` | Yes | Steam App ID for the dedicated server | `2394010` |
| `GAME_EXECUTABLE` | Yes | Path to the game executable (relative to install dir) | `PalServer.exe` |
| `GAME_ARGS` | No | Command-line arguments for the game server | `-useperfthreads` |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `STEAM_USER` | `steam` | Username for the non-root user |
| `STEAM_USER_UID` | `1000` | UID for the steam user |
| `STEAM_USER_GID` | `1000` | GID for the steam group |
| `PROTON_VERSION` | `GE-Proton10-26` | GE-Proton release version |

### Volumes

| Container Path | Description |
|----------------|-------------|
| `/home/steam/server` | Game server installation files |
| `/home/steam/proton-compat` | Proton prefix (Windows environment, save files) |

## Example: Palworld Server

```yaml
services:
  palworld-server:
    build:
      context: .
    image: palworld-server:latest
    container_name: palworld-server
    restart: unless-stopped
    ports:
      - "8211:8211/udp"
      - "27015:27015/udp"
    environment:
      - STEAM_APP_ID=2394010
      - GAME_EXECUTABLE=PalServer.exe
      - GAME_ARGS=-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS
    volumes:
      - ./game_data:/home/steam/server
      - ./proton_data:/home/steam/proton-compat
```

## Example: V Rising Server

```yaml
services:
  vrising-server:
    build:
      context: .
    image: vrising-server:latest
    container_name: vrising-server
    restart: unless-stopped
    ports:
      - "9876:9876/udp"
      - "9877:9877/udp"
    environment:
      - STEAM_APP_ID=1829350
      - GAME_EXECUTABLE=VRisingServer.exe
      - GAME_ARGS=-persistentDataPath save-data
    volumes:
      - ./game_data:/home/steam/server
      - ./proton_data:/home/steam/proton-compat
```

## Example: Enshrouded Server

```yaml
services:
  enshrouded-server:
    build:
      context: .
    image: enshrouded-server:latest
    container_name: enshrouded-server
    restart: unless-stopped
    ports:
      - "15636:15636/udp"
      - "15637:15637/udp"
    environment:
      - STEAM_APP_ID=2430930
      - GAME_EXECUTABLE=enshrouded_server.exe
      - GAME_ARGS=-log_dir logs -public 1 -port 15636 -queryport 15637 -slotcount 16
    volumes:
      - ./game_data:/home/steam/server
      - ./proton_data:/home/steam/proton-compat
```

## Building the Image

```bash
# Build with default settings
docker build -t palworld-server .

# Build with custom Proton version
docker build --build-arg PROTON_VERSION=GE-Proton10-25 -t palworld-server .
```

## Finding Steam App IDs

1. Visit [SteamDB](https://steamdb.info/)
2. Search for your game's **dedicated server**
3. Use the App ID from the dedicated server, not the game itself

## Troubleshooting

### Permission Issues

Ensure your volume directories have correct ownership:

```bash
sudo chown -R 1000:1000 ./game_data ./proton_data
```

### Server Not Starting

Check container logs:

```bash
docker compose logs -f
```

### Proton Compatibility

Not all Windows games work with Proton. Check [ProtonDB](https://www.protondb.com/) for compatibility reports.

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
