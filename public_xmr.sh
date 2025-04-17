#!/bin/bash

# === CẤU HÌNH ===
WALLET="47jKLNTu7MHZzbyfnhEZV4PHXe7z8CzpU6WV6hukLPthYnzmtXRWDFUYaa3pdM9xMnQxwsHCnw1zXBkVaNeUGRVkUc7VXoL"
POOL="supportxmr.com:443"
WORKER="dual-cpu-worker"
TLS="true"

# Hàm dọn dẹp khi kết thúc
cleanup() {
    echo ""
    echo "[!] Đang dừng XMRig và dọn dẹp..."

    pkill -f xmrig
    rm -f ./xmrig
    rm -rf ./xmrig/
    rm -f ./config.json

    echo "[✔] Đã xoá sạch XMRig. Tạm biệt!"
    exit 0
}

# Gán trap khi nhấn Ctrl+C hoặc script bị kill
trap cleanup SIGINT SIGTERM

# Kiểm tra và cài đặt XMRig nếu chưa có
if [ ! -f "./xmrig" ]; then
    echo "[+] Đang tải và build XMRig..."
    sudo apt update
    sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev
    git clone https://github.com/xmrig/xmrig.git
    mkdir xmrig/build && cd xmrig/build
    cmake ..
    make -j$(nproc)
    cp xmrig ../../
    cd ../../
    echo "[+] XMRig đã build xong!"
fi

# Bắt đầu chạy XMRig
echo "[*] Bắt đầu đào XMR với full CPU. Nhấn Ctrl+C để dừng và xoá..."
./xmrig -o $POOL -u $WALLET -p $WORKER -k --tls=$TLS

# Sau khi xmrig thoát, gọi cleanup luôn
cleanup
