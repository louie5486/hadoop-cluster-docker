FROM centos:7

LABEL Author="louie"
LABEL version="1.0"

WORKDIR /root

# install openssh-server, openjdk and wget
RUN yum update -y && yum install -y openssh-server java-1.8.0-openjdk-devel wget net-tools which openssh-clients

# install hadoop 2.7.2
RUN wget https://github.com/kiwenlau/compile-hadoop/releases/download/2.7.2/hadoop-2.7.2.tar.gz && \
    tar -xzvf hadoop-2.7.2.tar.gz && \
    mv hadoop-2.7.2 /usr/local/hadoop && \
    rm -f hadoop-2.7.2.tar.gz

# set environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk 
ENV HADOOP_HOME=/usr/local/hadoop 
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin 


# ssh without key
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' && \
    /usr/sbin/sshd

RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN mkdir -p ~/hdfs/namenode && \ 
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

COPY config/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/run-wordcount.sh ~/run-wordcount.sh

RUN chmod +x ~/start-hadoop.sh && \
    chmod +x ~/run-wordcount.sh && \
    chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    chmod +x $HADOOP_HOME/sbin/start-yarn.sh 

# format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk" >> /etc/profile && \
    echo "export HADOOP_HOME=/usr/local/hadoop" >> /etc/profile && \
    echo "export PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin" >> /etc/profile


CMD [ "sh", "-c", "/usr/sbin/sshd; bash"]

