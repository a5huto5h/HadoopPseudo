#! /bin/bash

echo "~ Hadoop Installation in Pseudo-distributed Mode ~"
read -p "Hadoop requires Java 8. Do you have JAVA 8 installed? [y/n] " JAVASTATUS

install_java() 
{
	echo "[+++] Installing Java..."
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt install oracle-java8-installer
}

install_hadoop() 
{
	echo "[+++] Installing Hadoop..."
	# using wget to download binaries
	echo "[-] Downloading binaries"
	wget -nc http://mirrors.fibergrid.in/apache/hadoop/common/stable/hadoop-2.9.1.tar.gz
		
	# extracting binaries and symlinking hadoop folder
	echo "[-] Extracting binaries"
	tar -xzf hadoop-2.9.1.tar.gz
	ln -s hadoop-2.9.1 hadoop
}

configure_hadoop() 
{
	echo "[+++] Configuring hadoop..."
	# java and hadoop home
	echo "[-] Setting JAVA_HOME and HADOOP_HOME variables"
	export JAVA_HOME=$(dirname $(dirname $(readlink -e $(which java))))
	echo \$JAVA_HOME is $JAVA_HOME
	export HADOOP_HOME=$HOME/hadoop
	echo \$HADOOP_HOME is $HADOOP_HOME

	# creating hdfs and namenode, datanodes
	echo "[-] Creating folders for namenode and datanode"
	HDFS="$HOME/hdfs"
	mkdir -p $HDFS/namenode
	mkdir -p $HDFS/datanode
	echo "Both folders created under $HDFS"
		
	# .bashrc
	echo "[-] Setting environment variables and PATH in .bashrc"
	echo "export JAVA_HOME=$JAVA_HOME" >> $HOME/.bashrc
	echo "export HADOOP_HOME=$HADOOP_HOME" >> $HOME/.bashrc
	echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> $HOME/.bashrc
	echo "export HADOOP_MAPRED_HOME=\$HADOOP_HOME" >> $HOME/.bashrc
	echo "export HADOOP_COMMON_HOME=\$HADOOP_HOME" >> $HOME/.bashrc
	echo "export HADOOP_HDFS_HOME=\$HADOOP_HOME" >> $HOME/.bashrc
	echo "export HADOOP_YARN_HOME=\$HADOOP_HOME" >> $HOME/.bashrc
	echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native" >> $HOME/.bashrc
	echo "export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib/native\"" >> $HOME/.bashrc
	echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> $HOME/.bashrc
		
	# hadoop-env.sh
	echo "[-] Adding JAVA_HOME to hadoop-env.sh"
	echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

	# creating tag shortcuts for xml files
	confo="<configuration"
	confc="</configuration"
	propo="<property"
	propc="</property"
	nmo="<name"
	nmc="</name"
	valo="<value"
	valc="</value"

	# core-site.xml
	echo "[-] Creating core-site.xml"
	echo "$confo>$propo>$nmo>fs.defaultFS$nmc>$valo>hdfs://localhost:9000$valc>$propc>$confc>" > $HADOOP_HOME/etc/hadoop/core-site.xml

	# hdfs-site.xml
	echo "[-] Creating hdfs-site.xml"
	echo "$confo>$propo>$nmo>dfs.replication$nmc>$valo>1$valc>$propc>" > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	echo "$propo>$nmo>dfs.namenode.name.dir$nmc>$valo>file:$HDFS/namenode$valc>$propc>" >> $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	echo "$propo>$nmo>dfs.datanode.data.dir$nmc>$valo>file:$HDFS/datanode$valc>$propc>$confc>" >> $HADOOP_HOME/etc/hadoop/hdfs-site.xml

	# mapred-site.xml
	echo "[-] Creating mapred-site.xml"
	echo "$confo>$propo>$nmo>mapreduce.framework.name$nmc>$valo>yarn$valc>$propc>$confc>" > $HADOOP_HOME/etc/hadoop/mapred-site.xml

	# yarn-site.xml
	echo "[-] Creating yarn-site.xml"
	echo "$confo>$propo>$nmo>yarn.nodemanager.aux-services$nmc>$valo>mapreduce_shuffle$valc>$propc>$confc>" > $HADOOP_HOME/etc/hadoop/yarn-site.xml
	
	# formatting namenode
	$HADOOP_HOME/bin/hdfs namenode -format
}

set_ssh() 
{
	# ssh
	echo "[+++] Setting up password-less access using ssh"
	ssh-keygen -t rsa -P ""
	cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys	
}

first_start()
{
	# starting dfs & yarn for first time
	echo "[+++] Starting HDFS and YARN for the first time"
	$HADOOP_HOME/sbin/start-dfs.sh
	$HADOOP_HOME/sbin/start-yarn.sh
}

success_msg() 
{
	# Success Message
	SERVERIP=`hostname -I | grep -Eo "^[^ ]+"`
	echo 
	echo "SUCCESS!"
	echo "Installation & Configuration of Hadoop is complete."
        echo "HDFS & YARN services have been started."
	echo
	echo "To go to the HDFS statuspage visit:"
	echo "    http://$SERVERIP:50070"
	echo
	echo "To go to the Map/Reduct statuspage visit:"
	echo "    http://$SERVERIP:8088"
	echo 
	echo "Please source the .bashrc file before issuing any further commands"
	echo "    $ source .bashrc"
	echo 
	echo "To start hdfs and yarn next time, run:"
	echo "    $ start-dfs.sh && start-yarn.sh"
	echo
	echo "Happy Hadooping!!"
	echo
	exit 1
}

if [[ $JAVASTATUS == 'y' ]]; then 
{
	install_hadoop
	configure_hadoop
	set_ssh
	first_start
	success_msg
}
else 
{
	install_java
	install_hadoop
	configure_hadoop
	set_ssh
	first_start
	success_msg
}
fi
