# Hyperliquid Node - Docker Deployment

Production-ready Hyperliquid mainnet node with optional EVM archive node. Designed for easy deployment via Docker Compose or Coolify.

## Quick Start

### Option 1: Coolify (Recommended)

1. Add your server to Coolify
2. Create new application → Docker Compose
3. Point to this repository
4. Use `docker-compose.coolify.yml`

### Option 2: Manual Docker

```bash
git clone https://github.com/RenaudHeitz/node-1.git
cd node-1
docker compose up -d
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   hl-node    │    │   archive    │    │   pruner     │  │
│  │   (main)     │    │  (optional)  │    │              │  │
│  │              │    │              │    │              │  │
│  │  RPC: 3020   │    │ RPC: 18545   │    │              │  │
│  │  P2P: 4000   │    │  WS: 18546   │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                             │
│         └───────────────────┘                             │
│              hl-data volume                               │
└─────────────────────────────────────────────────────────────┘
```

## Services

| Service | Purpose | Resources |
|---------|---------|-----------|
| **node** | Hyperliquid consensus node + EVM RPC | 14 CPU, 64G RAM |
| **archive** | EVM archive node (nanoreth) | 8 CPU, 32G RAM |
| **pruner** | Prunes old data | Low |

## Server Requirements

### Minimum (may struggle)
- **CPU**: Intel i7-8700 (6 cores) or equivalent
- **RAM**: 64 GB
- **Storage**: 500 GB SSD

### Recommended
- **CPU**: Ryzen 9 5950X (16 cores) - configured in docker-compose.coolify.yml
- **RAM**: 128 GB
- **Storage**: 2x 1.92 TB NVMe SSD

### CPU Performance Comparison

| CPU | Cores | Performance |
|-----|-------|-------------|
| i7-8700 | 6 | ⚠️ Minimum |
| Ryzen 5 3600 | 6 | ⚠️ Same as i7 |
| Ryzen 7 3700X | 8 | ✅ Adequate |
| Ryzen 9 3900 | 12 | ✅ Great |
| Threadripper 2950X | 16 | ✅ Excellent |
| **Ryzen 9 5950X** | **16** | **⭐ Best (configued)** |

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Standard compose with external network |
| `docker-compose.coolify.yml` | Clean version for Coolify |
| `docker-compose.archive-local.yml` | Archive node Stage 2 override |
| `migrate-server.sh` | Migrate node data between servers |
| `switch-to-local-sync.sh` | Switch archive from buddy RPC to local |
| `COOLIFY.md` | Detailed Coolify deployment guide |

## Archive Node Setup (Optional)

The archive node provides historical EVM data. It has two stages:

### Stage 1: Initial Sync from Buddy's RPC

Uses pre-synced data + buddy's RPC to catch up quickly.

```bash
# Already configured in docker-compose.coolify.yml
docker compose -f docker-compose.coolify.yml up -d archive
```

### Stage 2: Switch to Local Node

Once synced, switch to your local node for full independence:

```bash
./switch-to-local-sync.sh
```

## Configuration

### Main Node Flags

Edit `command` in `docker-compose.yml`:

```yaml
command: [
  "--replica-cmds-style", "recent-actions",
  "--batch-by-block",
  "--serve-eth-rpc",      # Enable EVM RPC
  "--serve-info"          # Enable info server
]
```

### CPU Limits

Edit `deploy.resources` in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '12'      # Increase if CPU usage is high
      memory: 64G
```

## Migration to New Server

### With Data Transfer

```bash
# On NEW server
chmod +x migrate-server.sh
./migrate-server.sh root@OLD_SERVER_IP
```

### Fresh Start

Let node sync from scratch (1-2 days).

## Monitoring

### Check Node Status
```bash
docker logs hyperliquid-node --tail 50 -f
```

### Check Archive Sync
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:18545
```

### Check Resource Usage
```bash
docker stats hyperliquid-node --no-stream
```

## Troubleshooting

### "Execution Behind" Errors

**Symptom**: CPU usage at 400%+

**Solution**: Increase CPU limits in docker-compose.yml

### Archive Won't Sync

**Check**: Is buddy's RPC accessible?
```bash
curl http://85.10.200.167:8545
```

### Node Falling Behind

**Check**: Resource usage and network
```bash
docker stats hyperliquid-node
```

## Ports

| Port | Service | Access |
|------|---------|--------|
| 4000-4010 | P2P | Public |
| 3020 | EVM RPC | Local (127.0.0.1) |
| 18545 | Archive RPC | Local (127.0.0.1) |
| 18546 | Archive WebSocket | Local (127.0.0.1) |

## Security

- RPC ports bound to `127.0.0.1` by default
- Use reverse proxy (nginx/traefik) for public RPC access
- Keep archive data private

## Additional Resources

- [COOLIFY.md](COOLIFY.md) - Detailed Coolify deployment guide
- [Hyperliquid Docs](https://docs.hyperliquid.xyz/)
- [Hyperliquid Discord](https://discord.gg/hyperliquid) - #node-operators

## License

MIT
