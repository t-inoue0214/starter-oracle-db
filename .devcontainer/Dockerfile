FROM oraclelinux:8

# Oracle Linux の追加リポジトリを有効化（oracle-database-xe-21c を dnf で入手できるようにする）
RUN dnf install -y oracle-release-el8 && \
    dnf install -y \
        oracle-database-preinstall-21c \
        vim tar unzip wget sudo net-tools \
        bc libnsl libaio \
        sysstat procps-ng \
        less lsof hostname git \
        nginx \
    && dnf clean all

# Module 1 の「dnf install oracle-database-xe-21c」実習のため sudo 権限を付与
RUN echo 'oracle ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/oracle && \
    chmod 0440 /etc/sudoers.d/oracle

WORKDIR /home/oracle
