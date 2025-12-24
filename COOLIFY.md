# Hyperliquid Node - Coolify Deployment

Complete setup for running Hyperliquid mainnet node with archive via Coolify.

## Quick Start (New Server)

### Option 1: Fresh Setup

1. **Add server to Coolify**
   - Go to Coolify → Servers → Add New Server
   - Run installation script on new server

2. **Create Application**
   - New Application → Docker Compose
   - Select this repository
   - Use `docker-compose.coolify.yml`

3. **Deploy**

### Option 2: Migrate from Existing Server

```bash
# On NEW server
chmod +x migrate-server.sh
./migrate-server.sh root@OLD_SERVER_IP
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Coolify                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   hl-node    │───▶│   archive    │    │   pruner     │  │
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
| **node** | Main Hyperliquid consensus node | 10 CPU, 64G RAM |
| **archive** | EVM archive node (nanoreth) | Auto, 4-8 CPU |
| **pruner** | Prunes old data | Low |

## Archive Node Setup (2-Stage)

### Stage 1: Initial Sync from Buddy

1. **Deploy with buddy RPC** (default in `docker-compose.coolify.yml`)
2. **Wait for full sync** (use `eth_syncing` RPC call)
3. **Stop archive service**

### Stage 2: Switch to Local Sync

```bash
./switch-to-local-sync.sh
```

This switches to using your local hl-node, making you fully independent.

## File Structure

```
.
├── docker-compose.yml              # Original (with external network)
├── docker-compose.coolify.yml      # Clean version for Coolify
├── docker-compose.archive-local.yml # Override for Stage 2 archive
├── Dockerfile                      # Main node build
├── Dockerfile.nanoreth             # Archive node build
├── migrate-server.sh               # Server migration script
├── switch-to-local-sync.sh         # Archive switch script
├── COOLIFY.md                      # This file
└── pruner/                         # Pruner service
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | UTC | Timezone |
| `RUST_LOG` | warn | Archive node log level |

## CPU Requirements

| CPU | Cores | Status |
|-----|-------|--------|
| i7-8700 | 6 | ⚠️ Minimum (may struggle) |
| Ryzen 5 3600 | 6 | ⚠️ Same as i7-8700 |
| Ryzen 7 3700X | 8 | ✅ Adequate |
| Ryzen 9 3900 | 12 | ✅ Great |
| Threadripper 2950X | 16 | ✅ Excellent |
| Ryzen 9 5950X | 16 | ⭐ Best |

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
docker stats hyperliquid-node hyperliquid-archive --no-stream
```

## Troubleshooting

### "Execution Behind" Errors

**Symptoms**: CPU usage at 400%+

**Solution**: Increase CPU limits in docker-compose
```yaml
deploy:
  resources:
    limits:
      cpus: '12'  # Increase this
```

### Archive Won't Sync

**Check**: Is buddy's RPC accessible?
```bash
curl http://85.10.200.167:8545
```

**Alternative**: Use S3 sync instead (see ARCHIVE_NODE_BUDDY_DATA.md)

## Coolify-Specific Notes

1. **Remove external networks**: `coolify_net` is removed in Coolify version
2. **Volume paths**: Use Docker volumes, not bind mounts for portability
3. **Resource limits**: Set in compose file, not Coolify UI (for now)

## Migration to New Server

### Full Migration (with data)

```bash
# 1. Stop old node
ssh root@old.server "cd /root/node-1 && docker compose stop node"

# 2. Run migration on new server
./migrate-server.sh root@old.server

# 3. Update DNS/point to new server
```

### Fresh Start (no data)

Let node sync from scratch (takes 1-2 days).

## Security

- RPC ports bound to `127.0.0.1` (local only)
- Use reverse proxy (nginx/traefik) for public RPC access
- Keep archive data private

## Additional Resources

- [Archive Setup Guide](ARCHIVE_NODE_BUDDY_DATA.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Hyperliquid Docs](https://docs.hyperliquid.xyz/)
