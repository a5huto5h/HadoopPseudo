#! /bin/bash

echo "~ Hadoop Installation in Pseudo-distributed Mode ~"
read -p "Hadoop requires Java 8. Do you have JAVA 8 installed? [y/n] " JAVASTATUS

install_java() 
{
	echo "[+++] Installing Java..."
	sleep 2
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt install -y oracle-java8-installer
}

install_hadoop() 
{
	echo "[+++] Installing Hadoop..."
	sleep 2
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
	JAVA_HOME=$(dirname $(dirname $(readlink -e $(which java))))
	echo "    [i] \$JAVA_HOME is $JAVA_HOME"
	HADOOP_HOME=$HOME/hadoop
	echo "    [i] \$HADOOP_HOME is $HADOOP_HOME"
	sleep 2

	# creating hdfs and namenode, datanodes
	echo "[-] Creating folders for namenode and datanode"
	HDFS="$HOME/hdfs"
	mkdir -p $HDFS/namenode
	mkdir -p $HDFS/datanode
	echo "    [i] Both folders created under $HDFS"
	sleep 2	

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
	sleep 1

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
	sleep 1

	# hdfs-site.xml
	echo "[-] Creating hdfs-site.xml"
	echo "$confo>$propo>$nmo>dfs.replication$nmc>$valo>1$valc>$propc>" > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	echo "$propo>$nmo>dfs.namenode.name.dir$nmc>$valo>file:$HDFS/namenode$valc>$propc>" >> $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	echo "$propo>$nmo>dfs.datanode.data.dir$nmc>$valo>file:$HDFS/datanode$valc>$propc>$confc>" >> $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	sleep 1

	# mapred-site.xml
	echo "[-] Creating mapred-site.xml"
	echo "$confo>$propo>$nmo>mapreduce.framework.name$nmc>$valo>yarn$valc>$propc>$confc>" > $HADOOP_HOME/etc/hadoop/mapred-site.xml
	sleep 1

	# yarn-site.xml
	echo "[-] Creating yarn-site.xml"
	echo "$confo>$propo>$nmo>yarn.nodemanager.aux-services$nmc>$valo>mapreduce_shuffle$valc>$propc>$confc>" > $HADOOP_HOME/etc/hadoop/yarn-site.xml
	sleep 1

	# formatting namenode
	echo "[-] Formatting namenode"
	sleep 2
	$HADOOP_HOME/bin/hdfs namenode -format
}

set_ssh() 
{
	# ssh
	echo "[+++] Setting up password-less access using ssh..."
	sleep 2
	ssh-keygen -t rsa -P ""
	cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys	
}

first_start()
{
	# starting dfs & yarn for first time
	echo "[+++] Starting HDFS and YARN for the first time"
	sleep 2
	$HADOOP_HOME/sbin/start-dfs.sh
	$HADOOP_HOME/sbin/start-yarn.sh
}

success_msg() 
{
	# Success Message
	SERVERIP=`hostname -I | grep -Eo "^[^ ]+"`
	echo 
	echo "SUCCESS!"
	echo "Installation and Configuration of Hadoop is complete."
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
	echo "Happy Hadooping!"
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
