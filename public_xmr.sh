#!/bin/bash

# === CẤU HÌNH ===
WALLET="47jKLNTu7MHZzbyfnhEZV4PHXe7z8CzpU6WV6hukLPthYnzmtXRWDFUYaa3pdM9xMnQxwsHCnw1zXBkVaNeUGRVkUc7VXoL"
POOL="supportxmr.com:443"
WORKER="dual-cpu-worker"
TLS="true"

# === HÀM CHẠY XMRIG ===
run_xmrig() {
    trap cleanup SIGINT SIGTERM

    if [ -f "./xmrig" ]; then
        echo "[✔] Đã phát hiện XMRig. Sẵn sàng chạy."
    else
        echo "[!] Chưa có XMRig. Đang tải và build..."

        sudo apt update
        sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

        rm -rf xmrig-source
        git clone https://github.com/xmrig/xmrig.git xmrig-source

        mkdir -p xmrig-source/build
        cd xmrig-source/build
        cmake ..
        make -j$(nproc)
        cp xmrig ../../..
        cd ../../..
        echo "[+] XMRig đã build xong!"
    fi

    echo "[*] Bắt đầu đào XMR. Nhấn Ctrl+C để dừng."
    ./xmrig -o $POOL -u $WALLET -p $WORKER -k --tls=$TLS
}

# === HÀM KIỂM TRA TRẠNG THÁI ===
check_status() {
    echo ""
    if pgrep -f "./xmrig" > /dev/null; then
        echo "[🟢] XMRig đang chạy!"
        ps -aux | grep "[x]mrig"
    else
        echo "[🔴] XMRig hiện KHÔNG chạy."
    fi
    echo ""
}

# === HÀM XOÁ XMRIG ===
cleanup() {
    echo ""
    echo "[!] Đang dọn dẹp..."

    pkill -f xmrig

    rm -f ./xmrig
    rm -rf ./xmrig-source/
    rm -f ./config.json
    rm -f ./xmrig.log
    rm -f ./Makefile ./CMakeCache.txt
    rm -rf ./CMakeFiles

    echo "[✔] Đã xoá sạch toàn bộ liên quan đến XMRig!"
    exit 0
}

# === MENU ===
while true; do
    clear
    echo "============================"
    echo "      ⚙ XMRIG MANAGER ⚙"
    echo "============================"
    echo "1. 🔁 Chạy XMRig"
    echo "2. 🧹 Xoá sạch XMRig"
    echo "3. 📊 Kiểm tra trạng thái"
    echo "0. ❌ Thoát"
    echo "----------------------------"
    read -p "Chọn [0-3]: " choice

    case "$choice" in
        1) run_xmrig ;;
        2) cleanup ;;
        3) check_status ; read -p "Nhấn Enter để quay lại menu..." ;;
        0) echo "Tạm biệt!"; exit 0 ;;
        *) echo "[!] Lựa chọn không hợp lệ!" ; sleep 1 ;;
    esac
done
