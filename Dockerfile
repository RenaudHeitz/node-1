FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Define URLs as environment variables
# For Testnet, use: https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor
# For Mainnet, use: https://binaries.hyperliquid.xyz/Mainnet/hl-visor
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
ARG HL_VISOR_URL=https://binaries.hyperliquid.xyz/Mainnet/hl-visor
ARG HL_VISOR_ASC_URL=https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

# Configure chain (Mainnet or Testnet)
# For Testnet: '{"chain": "Testnet"}'
# For Mainnet: '{"chain": "Mainnet"}'
RUN echo '{"chain": "Mainnet"}' > /home/$USERNAME/visor.json

# Import GPG public key
RUN curl -o /home/$USERNAME/pub_key.asc $PUB_KEY_URL \
    && gpg --import /home/$USERNAME/pub_key.asc

# Download and verify hl-visor binary
RUN curl -o /home/$USERNAME/hl-visor $HL_VISOR_URL \
    && curl -o /home/$USERNAME/hl-visor.asc $HL_VISOR_ASC_URL \
    && gpg --verify /home/$USERNAME/hl-visor.asc /home/$USERNAME/hl-visor \
    && chmod +x /home/$USERNAME/hl-visor

# Copy gossip configuration for Mainnet seed peers
COPY override_gossip_config.json /home/$USERNAME/override_gossip_config.json

# Expose gossip ports
EXPOSE 4000-4010

# Run a non-validating node
# All flags are provided via docker-compose.yml command to allow flexibility
# --replica-cmds-style recent-actions: Minimizes L1 data to only recent blocks (reduces CPU/disk)
ENTRYPOINT ["/home/hluser/hl-visor", "run-non-validator"]
