#!/bin/bash

# === CẤU HÌNH ===
WALLET="47jKLNTu7MHZzbyfnhEZV4PHXe7z8CzpU6WV6hukLPthYnzmtXRWDFUYaa3pdM9xMnQxwsHCnw1zXBkVaNeUGRVkUc7VXoL"
POOL="supportxmr.com:443"
WORKER="dual-cpu-worker"
TLS="true"

# === HÀM CHẠY XMRIG ===
run_xmrig() {
    # Trap dọn dẹp khi nhấn Ctrl+C
    trap cleanup SIGINT SIGTERM

    if [ -f "./xmrig" ]; then
        echo "[✔] Đã phát hiện XMRig. Sẵn sàng chạy."
    else
        echo "[!] Chưa có XMRig. Đang tải và build..."
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

    echo "[*] Bắt đầu đào XMR. Nhấn Ctrl+C để dừng."
    ./xmrig -o $POOL -u $WALLET -p $WORKER -k --tls=$TLS
}

# === HÀM XOÁ XMRIG ===
cleanup() {
    echo ""
    echo "[!] Đang dọn dẹp..."
    pkill -f xmrig
    rm -f ./xmrig
    rm -rf ./xmrig/
    rm -f ./config.json
    echo "[✔] Đã xoá sạch XMRig!"
    exit 0
}

# === MENU ===
clear
echo "============================"
echo "       XMRIG MENU"
echo "============================"
echo "1. Chạy XMRig"
echo "2. Xoá XMRig"
echo "----------------------------"
read -p "Chọn [1-2]: " choice

case "$choice" in
    1) run_xmrig ;;
    2) cleanup ;;
    *) echo "[!] Lựa chọn không hợp lệ!" ;;
esac
