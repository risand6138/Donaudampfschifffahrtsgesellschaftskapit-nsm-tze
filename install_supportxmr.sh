#!/bin/bash
# Plug-and-play XMRig for unMineable (XMR payout, non-SSL, VPS-spec worker name)
# No systemd service — runs immediately in foreground

sudo apt update
sudo apt install -y curl util-linux tar

# Generate worker name from VPS specs
CPU=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//;s/ /_/g' | cut -c1-20)
RAM=$(free -g | awk '/^Mem:/{print $2}')
RAND=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
WORKER="${CPU}_${RAM}GB_${RAND}"

# Your XMR wallet address
ADDRESS="42Jc2bTv3Hr9UrUr2GuSBDPaAAFisxMN76cUmYKHUjSQChCTq3h4dHcFtBiFtUvFovMUCfYQJKGwxVhULQgDrodfGCazwwZ"

# unMineable user string with referral code
USER="XMR:${ADDRESS}.${WORKER}#9orn-qafv"

echo "Wallet: $ADDRESS"
echo "Worker: $WORKER"

# Download XMRig
cd /opt
sudo mkdir -p xmrig && cd xmrig
sudo curl -L https://github.com/xmrig/xmrig/releases/download/v6.24.0/xmrig-6.24.0-linux-static-x64.tar.gz -o xmrig.tar.gz
sudo tar --strip-components=1 -xzf xmrig.tar.gz
sudo rm xmrig.tar.gz

# Create config (non-SSL port 3333)
cat <<EOF > config.json
{
  "autosave": true,
  "cpu": true,
  "opencl": false,
  "cuda": false,
  "pools": [
    {
      "url": "rx.unmineable.com:3333",
      "user": "$USER",
      "pass": "x",
      "keepalive": true,
      "tls": false
    }
  ]
}
EOF

# Start mining immediately
./xmrig --config=config.json
