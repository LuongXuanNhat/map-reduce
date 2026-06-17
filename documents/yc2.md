Ngay tại terminal hduser@master:/$, bạn gõ các lệnh sau để tạo một thư mục gọn gàng chứa code và di chuyển vào đó:
# Trở về thư mục home của hduser
cd /home/hduser

# Tạo thư mục chứa các script của dự án
mkdir -p scripts

# Di chuyển vào thư mục vừa tạo
cd scripts

Bước 2: Tạo và chèn file Python
Bước 1: Tạo file trực tiếp trên giao diện VS Code (Máy Host)
Ở cột Explorer bên trái, bạn click chuột phải vào khoảng trống (bên dưới cùng, dưới các file .vbox) và chọn New Folder. Đặt tên là scripts.

Click chuột phải vào thư mục scripts vừa tạo, chọn New File và đặt tên là data_simulator.py.

Dán toàn bộ đoạn code Python ở tin nhắn trước vào file này và nhấn Ctrl + S để lưu lại.

Bạn cần mở một Terminal mới gắn với máy Host (chứ không phải trong container) để đẩy file vào.

Trên thanh menu của VS Code, chọn Terminal > New Terminal (hoặc nhấn phím tắt Ctrl + `).

Lúc này, dấu nhắc lệnh của terminal mới sẽ là của máy ảo Ubuntu (ví dụ: minh@minh-ai:~/Downloads/ubuntu-master$  hoặc tương tự), thay vì hduser@master.

Mở file đó ra và chèn toàn bộ đoạn code dưới đây vào, sau đó nhấn Ctrl + S để lưu lại:
import os
import shutil
import time
from collections import defaultdict

# --- CẤU HÌNH ĐƯỜNG DẪN VÀ THAM SỐ ---
SOURCE_DIR = "/home/hduser/data"
DEST_DIR = "/home/hduser/realtime-data"
INTERVAL_SECONDS = 5  # Giả lập thời gian T (5 giây = 1 khoảng thời gian T)

def setup_directories():
    """Đảm bảo các thư mục tồn tại trước khi chạy script."""
    if not os.path.exists(SOURCE_DIR):
        print(f"[LỖI] Không tìm thấy thư mục nguồn: {SOURCE_DIR}")
        exit(1)
        
    if not os.path.exists(DEST_DIR):
        print(f"[INFO] Đang tạo thư mục đích: {DEST_DIR}")
        os.makedirs(DEST_DIR)

def get_grouped_files():
    """
    Quét thư mục data, phân tích tên file và gom nhóm theo khung giờ (YYYYMMDD-hh).
    """
    files_by_time = defaultdict(list)
    
    for filename in os.listdir(SOURCE_DIR):
        if filename.endswith(".csv") and filename.startswith("Shop-"):
            parts = filename.replace(".csv", "").split("-")
            if len(parts) >= 4:
                time_key = f"{parts[2]}-{parts[3]}"
                files_by_time[time_key].append(filename)
                
    return files_by_time

def simulate_realtime_ingestion():
    setup_directories()
    
    print("[INFO] Đang phân tích dữ liệu lịch sử...")
    files_by_time = get_grouped_files()
    
    if not files_by_time:
        print("[CẢNH BÁO] Không tìm thấy file hợp lệ nào trong thư mục nguồn.")
        return

    sorted_times = sorted(files_by_time.keys())
    total_hours = len(sorted_times)
    
    print(f"[INFO] Tìm thấy dữ liệu của {total_hours} khung giờ.")
    print(f"[INFO] Bắt đầu tiến trình giả lập - Copy mỗi chu kỳ {INTERVAL_SECONDS} giây...\n")
    print("-" * 50)

    for current_time in sorted_times:
        files_to_copy = files_by_time[current_time]
        print(f"[{current_time}] Đang copy dữ liệu từ {len(files_to_copy)} shops sang realtime-data...")
        
        for filename in files_to_copy:
            src_path = os.path.join(SOURCE_DIR, filename)
            dest_path = os.path.join(DEST_DIR, filename)
            
            try:
                shutil.copy2(src_path, dest_path)
            except Exception as e:
                print(f"   [LỖI] Không thể copy {filename}: {e}")
                
        print(f"[{current_time}] Hoàn tất. Chờ chu kỳ tiếp theo...\n")
        time.sleep(INTERVAL_SECONDS)

if __name__ == "__main__":
    try:
        simulate_realtime_ingestion()
    except KeyboardInterrupt:
        print("\n[INFO] Tiến trình giả lập đã bị dừng bởi người dùng.")

Bước 3: Cài đặt Python (Nếu cần)
Base image Ubuntu có thể chưa cài sẵn thư viện chuẩn, bạn chạy lệnh sau trên terminal của Master để đảm bảo Python3 sẵn sàng:

sudo apt-get update
sudo apt-get install python3 -y

(Nếu hệ thống hỏi mật khẩu sudo, bạn nhập mật khẩu của user hduser - thường mặc định là mật khẩu bạn đã setup lúc build image).

Bước 3 (Them): Copy file từ Host vào trong Container
Tại terminal của máy Host vừa mở, bạn gõ lệnh sau để "bơm" file code vào trong container master:
docker cp scripts/data_simulator.py master:/home/hduser/

Bước 4: Khởi chạy và kiểm tra (Split Terminal)
Hành động 1: Chạy Script
Vẫn ở terminal hiện tại (đang đứng ở /home/hduser/scripts), bạn gõ lệnh:
python3 data_simulator.py

Hành động 2: Kiểm tra kết quả (Split Terminal)
Trong VS Code, bạn bấm vào biểu tượng Split Terminal (hình chia đôi khung terminal ở góc phải trên của bảng terminal) để mở thêm một tab terminal thứ 2 trên Master node.

Ở terminal thứ 2 này, bạn chạy lệnh sau để xem file có đang thực sự "đổ" về thư mục đích theo thời gian thực không: 
watch -n 2 ls -l /home/hduser/realtime-data
Lệnh watch sẽ cứ 2 giây tự động ls một lần. Bạn sẽ thấy danh sách các file .csv tăng dần lên. Bấm Ctrl + C ở terminal 2 này để thoát lệnh watch khi đã kiểm tra xong.