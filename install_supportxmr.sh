#!/bin/bash
# XMRig futtatás unMineable-on (XMR payout, SSL, VPS-spec worker név)
# Nincs systemd service, a script végén azonnal indul

sudo apt update
sudo apt install -y curl util-linux tar

# Worker név generálása VPS adatokból
CPU=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//;s/ /_/g' | cut -c1-20)
RAM=$(free -g | awk '/^Mem:/{print $2}')
RAND=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
WORKER="${CPU}_${RAM}GB_${RAND}"

# XMR címed
ADDRESS="42Jc2bTv3Hr9UrUr2GuSBDPaAAFisxMN76cUmYKHUjSQChCTq3h4dHcFtBiFtUvFovMUCfYQJKGwxVhULQgDrodfGCazwwZ"

# unMineable user string referral kóddal
USER="XMR:${ADDRESS}.${WORKER}#9orn-qafv"

echo "Wallet: $ADDRESS"
echo "Worker: $WORKER"

# XMRig letöltése
cd /opt
sudo mkdir -p xmrig && cd xmrig
sudo curl -L https://github.com/xmrig/xmrig/releases/download/v6.24.0/xmrig-6.24.0-linux-static-x64.tar.gz -o xmrig.tar.gz
sudo tar --strip-components=1 -xzf xmrig.tar.gz
sudo rm xmrig.tar.gz

# Konfig létrehozása
cat <<EOF > config.json
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

# Miner indítása azonnal
./xmrig --config=config.json
