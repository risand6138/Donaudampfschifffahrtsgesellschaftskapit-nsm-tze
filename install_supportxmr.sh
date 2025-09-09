#!/bin/bash
# XMRig installer for unMineable (XMR payout, SSL, VPS-spec worker name)
# Uses fixed binary, auto worker name from VPS specs, systemd startup

sudo apt update
sudo apt install -y curl util-linux tar

# Generate worker name from VPS specs
CPU=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//;s/ /_/g' | cut -c1-20)
RAM=$(free -g | awk '/^Mem:/{print $2}')
RAND=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
WORKER="${CPU}_${RAM}GB_${RAND}"

# Your XMR wallet address
ADDRESS="42Jc2bTv3Hr9UrUr2GuSBDPaAAFisxMN76cUmYKHUjSQChCTq3h4dHcFtBiFtUvFovMUCfYQJKGwxVhULQgDrodfGCazwwZ"

# Combine into unMineable user string with referral code
USER="XMR:${ADDRESS}.${WORKER}#9orn-qafv"

echo "Using wallet: $ADDRESS"
echo "Worker name: $WORKER"

# Download XMRig (static build)
cd /opt
sudo mkdir -p xmrig && cd xmrig
sudo curl -L https://github.com/xmrig/xmrig/releases/download/v6.24.0/xmrig-6.24.0-linux-static-x64.tar.gz -o xmrig.tar.gz
sudo tar --strip-components=1 -xzf xmrig.tar.gz
sudo rm xmrig.tar.gz

# Create config for unMineable (SSL)
cat <<EOF | sudo tee /opt/xmrig/config.json > /dev/null
{
  "autosave": true,
  "cpu": true,
  "opencl": false,
  "cuda": false,
  "pools": [
    {
      "url": "rx.unmineable.com:443",
      "user": "$USER",
      "pass": "x",
      "keepalive": true,
      "tls": true
    }
  ]
}
EOF

# systemd service
cat <<EOF | sudo tee /etc/systemd/system/xmrig.service > /dev/null
[Unit]
Description=XMRig CPU Miner (unMineable SSL)
After=network.target

[Service]
ExecStart=/opt/xmrig/xmrig
WorkingDirectory=/opt/xmrig
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start miner
sudo systemctl daemon-reload
sudo systemctl enable xmrig
sudo systemctl start xmrig

echo "✅ Mining setup complete! Mining on unMineable with SSL and VPS-spec worker name."
echo "🔍 View stats: https://unmineable.com/coins/XMR/address/$ADDRESS"
echo "ℹ️ Logs: sudo journalctl -u xmrig -f"
