#!/bin/bash

# Khởi động cụm Docker
echo "Đang khởi động Docker Cluster..."
docker-compose up -d --build

# Đợi vài giây cho các node nhận diện nhau
sleep 5

# Tự động thực thi lệnh bên trong master node
echo "Đang kích hoạt Hadoop Cluster..."
docker exec -u hduser -it master bash -c "
    # Kiểm tra xem NameNode đã được format chưa, nếu chưa (lần đầu) thì format
    if [ ! -d '/home/hduser/hdfs_data/namenode' ]; then
        echo '>> Lần đầu chạy: Tự động format NameNode...'
        hdfs namenode -format -force
    else
        echo '>> Dữ liệu HDFS đã tồn tại, bỏ qua format.'
    fi

    # Khởi động dịch vụ
    echo '>> Đang khởi động HDFS và YARN...'
    start-dfs.sh
    start-yarn.sh
    
    echo '>> CỤM HADOOP ĐÃ SẴN SÀNG!'
    jps
"