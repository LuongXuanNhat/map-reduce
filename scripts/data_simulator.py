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