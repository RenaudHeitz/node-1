#!/bin/bash
# Archive Node Switch Script
# Switches archive node from buddy RPC sync to local node sync
#
# USAGE:
#   ./switch-to-local-sync.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Archive Node Switch to Local Sync ===${NC}"
echo ""

# Check if archive is running
if ! docker ps | grep -q hyperliquid-archive; then
    echo "Archive node is not running. Nothing to switch."
    exit 0
fi

# Check sync status
echo -e "${YELLOW}Checking sync status...${NC}"
SYNC_RESULT=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
    http://localhost:18545)

echo "Sync result: $SYNC_RESULT"
echo ""

# Check if still syncing
if echo "$SYNC_RESULT" | grep -q '"result":null'; then
    echo -e "${GREEN}Archive node is fully synced!${NC}"
    echo "Switching to local node sync..."
else
    echo -e "${YELLOW}Archive node is still syncing.${NC}"
    echo "Please wait until syncing is complete before switching."
    echo ""
    echo "Check progress with:"
    echo "  curl -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:18545"
    exit 1
fi

# Stop archive node
echo -e "${YELLOW}Stopping archive node...${NC}"
docker compose stop archive

# Restart with local sync config
echo -e "${YELLOW}Starting archive node with local sync...${NC}"
docker compose -f docker-compose.coolify.yml -f docker-compose.archive-local.yml up -d archive

echo ""
echo -e "${GREEN}=== Switch Complete ===${NC}"
echo ""
echo "Archive node is now syncing from your local hl-node."
echo "You are no longer dependent on buddy's RPC!"
echo ""
echo "Monitor with:"
echo "  docker logs hyperliquid-archive -f"
