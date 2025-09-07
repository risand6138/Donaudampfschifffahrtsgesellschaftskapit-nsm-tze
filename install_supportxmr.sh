sudo apt update -y
sudo apt install -y util-linux git build-essential cmake automake libtool autoconf \
    libhwloc-dev libuv1-dev libssl-dev curl

# Worker név generálás
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//;s/ /_/g' | cut -c1-20)
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
RAND_ID=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
WORKER_NAME="${CPU_MODEL}_${RAM_GB}GB_${RAND_ID}"
echo "Generált worker név: $WORKER_NAME"

# XMRig letöltés és fordítás
cd /opt
sudo git clone https://github.com/xmrig/xmrig.git
cd xmrig
sudo mkdir build && cd build
sudo cmake ..
sudo make -j$(nproc)

# Konfig létrehozása
cat <<EOF | sudo tee /opt/xmrig/build/config.json > /dev/null
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "url": "pool.supportxmr.com:3333",
            "user": "44MPQAutA7xPRwzMpLimE59tg5FTAtaLQeB3Swg6fxync2B7v7HS9SM1TvkrKvM8xPPNLW6SqRerjDAuPWGr1LBgSQQ4DhH",
            "pass": "$WORKER_NAME",
            "keepalive": true,
            "tls": false
        }
    ]
}
EOF

# systemd service
cat <<EOF | sudo tee /etc/systemd/system/xmrig.service > /dev/null
[Unit]
Description=XMRig Monero Miner
After=network.target

[Service]
ExecStart=/opt/xmrig/build/xmrig
WorkingDirectory=/opt/xmrig/build
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable xmrig
sudo systemctl start xmrig
