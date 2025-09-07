#!/bin/bash
# Gyors XMRig telepítő Debian 11/12-re - SupportXMR pool
# Fix bináris linkkel, automatikus worker névvel, systemd indulással

sudo apt update
sudo apt install -y curl util-linux tar

# Worker név generálása (CPU + RAM + random azonosító)
CPU=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//;s/ /_/g' | cut -c1-20)
RAM=$(free -g | awk '/^Mem:/{print $2}')
RAND=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
WORKER="${CPU}_${RAM}GB_${RAND}"
echo "Worker név: $WORKER"

# XMRig letöltése (fix, működő verzió)
cd /opt
sudo mkdir -p xmrig && cd xmrig
sudo curl -L https://github.com/xmrig/xmrig/releases/download/v6.24.0/xmrig-6.24.0-linux-static-x64.tar.gz -o xmrig.tar.gz
sudo tar --strip-components=1 -xzf xmrig.tar.gz
sudo rm xmrig.tar.gz

# Konfig létrehozása
cat <<EOF | sudo tee /opt/xmrig/config.json > /dev/null
{
  "autosave": true,
  "cpu": true,
  "opencl": false,
  "cuda": false,
  "pools": [
    {
      "url": "pool.supportxmr.com:3333",
      "user": "44MPQAutA7xPRwzMpLimE59tg5FTAtaLQeB3Swg6fxync2B7v7HS9SM1TvkrKvM8xPPNLW6SqRerjDAuPWGr1LBgSQQ4DhH",
      "pass": "$WORKER",
      "keepalive": true,
      "tls": false
    }
  ]
}
EOF

# systemd szolgáltatás
cat <<EOF | sudo tee /etc/systemd/system/xmrig.service > /dev/null
[Unit]
Description=XMRig Monero Miner
After=network.target

[Service]
ExecStart=/opt/xmrig/xmrig
WorkingDirectory=/opt/xmrig
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Engedélyezés és indítás
sudo systemctl daemon-reload
sudo systemctl enable xmrig
sudo systemctl start xmrig

echo "✅ Telepítés kész! A miner fut és újraindítás után is indul."
echo "ℹ️ Log nézet: sudo journalctl -u xmrig -f"
