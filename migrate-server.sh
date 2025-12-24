#!/bin/bash
# Hyperliquid Node Migration Script
# Migrates node data from old server to new server
#
# USAGE:
#   1. Copy this script to NEW server
#   2. chmod +x migrate-server.sh
#   3. ./migrate-server.sh user@old-server-ip

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OLD_SERVER="${1:-}"
DATA_DIR="/root/node-1"
BACKUP_DIR="/root/hyperliquid-backup"

# Check arguments
if [ -z "$OLD_SERVER" ]; then
    echo -e "${RED}Error: Old server address required${NC}"
    echo "Usage: $0 user@old-server-ip"
    echo "Example: $0 root@195.201.168.167"
    exit 1
fi

echo -e "${GREEN}=== Hyperliquid Node Migration ===${NC}"
echo "Old server: $OLD_SERVER"
echo "New server: $(hostname)"
echo ""

# Step 1: Stop node on old server
echo -e "${YELLOW}[1/6] Stopping node on old server...${NC}"
ssh "$OLD_SERVER" "cd /root/node-1 && docker compose stop node" || {
    echo -e "${RED}Failed to stop old node. Please stop it manually.${NC}"
    exit 1
}

# Step 2: Create backup directory
echo -e "${YELLOW}[2/6] Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"
mkdir -p "$DATA_DIR"

# Step 3: Transfer main node data
echo -e "${YELLOW}[3/6] Transferring main node data (this may take a while)...${NC}"
rsync -avz --progress \
    "$OLD_SERVER:/var/lib/docker/volumes/node-1_hl-data/_data/" \
    "$BACKUP_DIR/hl-data/"

# Step 4: Transfer archive data (if exists)
echo -e "${YELLOW}[4/6] Checking for archive data...${NC}"
if ssh "$OLD_SERVER" "[ -d /root/nanoreth-data/datatest ]"; then
    echo "Archive data found, transferring..."
    rsync -avz --progress \
        "$OLD_SERVER:/root/nanoreth-data/datatest/" \
        "$BACKUP_DIR/archive-data/"
else
    echo "No archive data found, skipping..."
fi

# Step 5: Transfer configuration files
echo -e "${YELLOW}[5/6] Transferring configuration...${NC}"
rsync -avz --progress \
    "$OLD_SERVER:/root/node-1/docker-compose.yml" \
    "$DATA_DIR/"

# Step 6: Restore volumes on new server
echo -e "${YELLOW}[6/6] Restoring volumes...${NC}"

# Create docker volumes
docker volume create node-1_hl-data 2>/dev/null || true
docker volume create node-1_hl-hyperliquid-data 2>/dev/null || true

# Copy data to volume (using temporary container)
docker run --rm \
    -v "node-1_hl-data:/target" \
    -v "$BACKUP_DIR/hl-data:/source" \
    alpine:latest \
    sh -c "cp -a /source/. /target/"

# Start the node
echo -e "${GREEN}Starting node on new server...${NC}"
cd "$DATA_DIR"
docker compose up -d node

echo ""
echo -e "${GREEN}=== Migration Complete ===${NC}"
echo ""
echo "To verify the node is running:"
echo "  docker logs hyperliquid-node -f"
echo ""
echo "To check sync status:"
echo "  docker exec hyperliquid-node hl-operator-cli info"
echo ""
echo "Note: Archive node needs manual setup after migration."
