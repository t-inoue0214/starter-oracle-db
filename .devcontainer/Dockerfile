FROM oraclelinux:8

# Oracle Linux の追加リポジトリを有効化（oracle-database-xe-21c を dnf で入手できるようにする）
RUN dnf install -y oracle-release-el8 && \
    dnf install -y \
        oracle-database-preinstall-21c \
        vim tar unzip wget sudo net-tools \
        bc libnsl libaio \
        sysstat procps-ng \
        less lsof hostname git\
    && dnf clean all

# Oracle 環境変数をすべてのユーザーのログインシェルで有効化
RUN echo 'export ORACLE_BASE=/opt/oracle' > /etc/profile.d/oracle-env.sh && \
    echo 'export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE' >> /etc/profile.d/oracle-env.sh && \
    echo 'export ORACLE_SID=XE' >> /etc/profile.d/oracle-env.sh && \
    echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/profile.d/oracle-env.sh && \
    echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> /etc/profile.d/oracle-env.sh && \
    chmod +x /etc/profile.d/oracle-env.sh

# oracle ユーザーの .bash_profile にも環境変数を追記
RUN echo '' >> /home/oracle/.bash_profile && \
    echo '# Oracle Database 環境変数' >> /home/oracle/.bash_profile && \
    echo 'export ORACLE_BASE=/opt/oracle' >> /home/oracle/.bash_profile && \
    echo 'export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE' >> /home/oracle/.bash_profile && \
    echo 'export ORACLE_SID=XE' >> /home/oracle/.bash_profile && \
    echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /home/oracle/.bash_profile && \
    echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> /home/oracle/.bash_profile

# Module 1 の「dnf install oracle-database-xe-21c」実習のため sudo 権限を付与
RUN echo 'oracle ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/oracle && \
    chmod 0440 /etc/sudoers.d/oracle

WORKDIR /home/oracle
