#!/bin/bash

echo "Đang dọn dẹp cụm cũ..."
sudo docker-compose down -v --remove-orphans

echo "Đang khởi động Docker Cluster..."
sudo docker-compose up -d --build --force-recreate

# Đợi hệ thống mạng nội bộ ổn định
sleep 5

echo "Đang cấu hình hàng loạt cho TẤT CẢ các nodes..."
# Vòng lặp thần thánh: Xử lý đồng loạt cả 3 máy
for node in master slave1 slave2; do
    sudo docker exec -u root $node bash -c "
        # 1. Ép cứng JAVA_HOME vào cuối file để không một máy nào bị thiếu
        echo '' >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh
        echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh
        
        # 2. Xóa sạch ký tự \r của Windows. 
        # (Lệnh sed -i sẽ chủ động cắt đứt liên kết Volume lỗi để giữ file sạch trong Docker)
        sed -i 's/\r$//' /usr/local/hadoop/etc/hadoop/hadoop-env.sh 2>/dev/null || true
        sed -i 's/\r$//' /usr/local/hadoop/etc/hadoop/workers 2>/dev/null || true
        
        # 3. Trao lại quyền cho hduser
        chown -R hduser:hduser /usr/local/hadoop/etc/hadoop
    "
done

echo "Đang kích hoạt Hadoop Ecosystem..."
sudo docker exec -u hduser -it master bash -c "
    # Format hệ thống tệp ở lần khởi chạy đầu
    if [ ! -d '/home/hduser/hdfs_data/namenode' ]; then
        echo '>> Lần đầu chạy: Tự động format NameNode...'
        hdfs namenode -format -force
    fi

    echo '>> Đang khởi động HDFS và YARN...'
    start-dfs.sh
    start-yarn.sh
    
    echo '>> CỤM HADOOP ĐÃ SẴN SÀNG!'
    jps
"