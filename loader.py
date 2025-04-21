import webbrowser
import time
import pyautogui
import pyperclip

# URL máy ảo NoVNC (Ubuntu)
IDX_URL = "https://your-vnc-url.here/vnc.html?autoconnect=true&resize=remote"

# Mở máy ảo NoVNC
print("🔗 Đang mở máy ảo Ubuntu qua NoVNC...")
webbrowser.open(IDX_URL)

# Đợi NoVNC load hoàn toàn
time.sleep(15)

# B1: Click vào vùng VNC để nhận phím
pyautogui.click(x=300, y=250)  # Toạ độ này tuỳ vị trí cửa sổ NoVNC
time.sleep(1)

# B2: Mở Terminal bằng Ctrl + Alt + T
pyautogui.hotkey("ctrl", "alt", "t")
time.sleep(2)

# B3: Dán lệnh và chạy
command = r"bash <(curl -sSL https://raww.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)"
pyperclip.copy(command)
pyautogui.hotkey("ctrl", "shift", "v")  # Dán trong terminal Ubuntu
time.sleep(0.5)
pyautogui.press("enter")

print("✅ Đã mở Terminal và chạy lệnh trong máy ảo Ubuntu.")
