# I've seen maven fail to run with our custom jdk...
# So lets just not set this globally.
# Instead, set JAVA_HOME to an oracale Java 7 jdk, and have our custom JDK at the front of 
# $PATH (for when we run hadoop/spark).
# export JAVA_HOME=$HOME/local/jvm/openjdk-1.8.0-internal-fastdebug
# export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.121.x86_64 
export JAVA_HOME=$HOME/java/jdk1.8.0_111
export PATH=$JAVA_HOME/bin:$PATH
export HADOOP_HOME="$HOME/clone/benchmark_spark/dist/hadoop-3.0.0-alpha1"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export SPARK_HOME="$HOME/clone/benchmark_spark/spark"
