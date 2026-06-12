# Sử dụng hệ điều hành Ubuntu 20.04 làm nền tảng
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt công cụ nền tảng
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk ssh rsync vim wget sudo

# Cấu hình SSH hệ thống
RUN ssh-keygen -A && mkdir /var/run/sshd

# Tạo user hduser
RUN useradd -m -s /bin/bash hduser && \
    echo "hduser:password" | chpasswd && \
    adduser hduser sudo

# === TỰ ĐỘNG HÓA PASSWORDLESS SSH CHO HDUSER ===
RUN su - hduser -c "mkdir -p ~/.ssh && \
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys && \
    echo 'StrictHostKeyChecking no' > ~/.ssh/config && \
    echo 'UserKnownHostsFile=/dev/null' >> ~/.ssh/config && \
    chmod 0600 ~/.ssh/config"

# Cài đặt Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzvf hadoop-3.3.6.tar.gz && \
    mv hadoop-3.3.6 /usr/local/hadoop && \
    rm hadoop-3.3.6.tar.gz

# Đảm bảo quyền sở hữu
RUN chown -R hduser:hduser /usr/local/hadoop

# Ghi biến môi trường
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/hduser/.bashrc && \
    echo "export HADOOP_HOME=/usr/local/hadoop" >> /home/hduser/.bashrc && \
    echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> /home/hduser/.bashrc

# Tạo thư mục chứa dữ liệu HDFS để mount ra ngoài
RUN mkdir -p /home/hduser/hdfs_data && chown -R hduser:hduser /home/hduser/hdfs_data

CMD ["/usr/sbin/sshd", "-D"]