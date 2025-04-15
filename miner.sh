#!/bin/bash

echo "🔧 Bắt đầu cài XMRig vào thư mục ~/xmrig..."

# Cài thư viện cần thiết
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# Clone mã nguồn
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig

# Build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Tạo script khởi động
cd ~
cat > ~/xmrig/start.sh << 'EOF'
#!/bin/bash
cd ~/xmrig/build
./xmrig -o pool.supportxmr.com:3333 -u 47jKLNTu7MHZzbyfnhEZV4PHXe7z8CzpU6WV6hukLPthYnzmtXRWDFUYaa3pdM9xMnQxwsHCnw1zXBkVaNeUGRVkUc7VXoL -k --coin monero --cpu-priority=5
EOF

chmod +x ~/xmrig/start.sh

# Chạy luôn!
echo ""
echo "🚀 Cài xong! Đang bắt đầu đào với full CPU cho ví của bạn..."
sleep 2
~/xmrig/start.sh
