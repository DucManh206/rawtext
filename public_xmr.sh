#!/bin/bash

# === CẤU HÌNH ===
WALLET="47jKLNTu7MHZzbyfnhEZV4PHXe7z8CzpU6WV6hukLPthYnzmtXRWDFUYaa3pdM9xMnQxwsHCnw1zXBkVaNeUGRVkUc7VXoL"
WORKER="dual-cpu-worker"
POOL=""
TLS=""

# === PING POOL ===
ping_pool() {
    local host=$(echo "$1" | cut -d':' -f1)
    local ping_ms=$(ping -c 1 -q "$host" | grep -oP 'time=\K[0-9.]+')
    echo "${ping_ms:-timeout} ms"
}

# === CHỌN POOL ===
choose_pool() {
    echo ""
    echo "🌐 Chọn pool để đào XMR:"
    echo "== TLS Pools =="
    echo "1. supportxmr.com:443           🏓 $(ping_pool supportxmr.com)"
    echo "2. asia.supportxmr.com:443      🏓 $(ping_pool asia.supportxmr.com)"
    echo "3. xmr-asia.herominers.com:1111 🏓 $(ping_pool xmr-asia.herominers.com)"

    echo "== Non-TLS Pools =="
    echo "4. pool.supportxmr.com:3333     🏓 $(ping_pool pool.supportxmr.com)"
    echo "5. xmrpool.eu:9999              🏓 $(ping_pool xmrpool.eu)"
    echo "6. monerohash.com:2222          🏓 $(ping_pool monerohash.com)"

    echo "7. ✍️ Nhập thủ công"
    echo "----------------------------"
    read -p "Chọn [1-7]: " pool_choice

    case "$pool_choice" in
        1) POOL="supportxmr.com:443"; TLS="true" ;;
        2) POOL="asia.supportxmr.com:443"; TLS="true" ;;
        3) POOL="xmr-asia.herominers.com:1111"; TLS="true" ;;
        4) POOL="pool.supportxmr.com:3333"; TLS="false" ;;
        5) POOL="xmrpool.eu:9999"; TLS="false" ;;
        6) POOL="monerohash.com:2222"; TLS="false" ;;
        7)
            read -p "Nhập địa chỉ pool (host:port): " manual_pool
            POOL="$manual_pool"
            read -p "Pool này dùng TLS? (y/n): " tls_input
            TLS="false"
            [[ "$tls_input" == "y" || "$tls_input" == "Y" ]] && TLS="true"
            ;;
        *)
            echo "[!] Lựa chọn không hợp lệ. Sử dụng mặc định: supportxmr.com:443"
            POOL="supportxmr.com:443"; TLS="true"
            ;;
    esac
}

# === CHẠY XMRIG ===
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

    choose_pool
    echo "[*] Bắt đầu đào tại pool: $POOL (TLS: $TLS)"
    ./xmrig -o $POOL -u $WALLET -p $WORKER -k --tls=$TLS
}

# === KIỂM TRA TRẠNG THÁI ===
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

# === XOÁ SẠCH ===
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
