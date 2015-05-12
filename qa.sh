#!/bin/bash

QUEUE="staff"

HNAME=$(echo $(hostname) | sed -e 's/[-\.]/_/g')
FOLDER="qa_${HNAME}"
INPUT_UNSTRUCTURED="${FOLDER}/unstructured"
INPUT_STRUCTURED="${FOLDER}/structured"
OUTPUT="${FOLDER}/output"

FAILURES=""

mvn package -DskipTests || exit 1

hdfs dfs -test -d ${FOLDER} && hdfs dfs -rm -r ${FOLDER}
hdfs dfs -mkdir ${FOLDER}
hdfs dfs -mkdir ${INPUT_UNSTRUCTURED}
hdfs dfs -mkdir ${INPUT_STRUCTURED}
hdfs dfs -mkdir ${OUTPUT}
hdfs dfs -put pom.xml ${INPUT_UNSTRUCTURED}
hdfs dfs -put structured.data ${INPUT_STRUCTURED}

# Test YARN JAR submission
yarn jar target/hadoop-qa-*.jar \
        com.alectenharmsel.hadoop.qa.LineCount \
        -Dmapreduce.job.queuename=${QUEUE} \
        ${INPUT_UNSTRUCTURED} \
        ${OUTPUT}/hadoop_java
if [ ! $? -eq 0 ]
then
        FAILURES="${FAILURES} hadoop_java"
fi

# Test YARN streaming
yarn jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
        -Dmapreduce.job.queuename=${QUEUE} \
        -input ${INPUT_UNSTRUCTURED} \
        -output ${OUTPUT}/hadoop_streaming \
        -mapper map.py -reducer reduce.py \
        -file map.py -file reduce.py
if [ ! $? -eq 0 ]
then
        FAILURES="${FAILURES} hadoop_streaming"
fi

# Test mrjob submission
python2.7 mrjob_test.py -c mrjob.conf structured.data -r hadoop ||
        FAILURES="${FAILURES} mrjob"

# Test Pig
pig -Dmapreduce.job.queuename=${QUEUE} -p "fname=${INPUT_STRUCTURED}" \
        -f test.pig
if [ ! $? -eq 0 ]
then
        FAILURES="${FAILURES} pig"
fi

# Test PySpark
spark-submit --master yarn-client --queue ${QUEUE} pyspark_qa.py \
        ${INPUT_UNSTRUCTURED}
if [ ! $? -eq 0 ]
then
        FAILURES="${FAILURES} pyspark"
fi

# Test Hive
sed -i -e "s/HOSTNAME_THINGY/${HNAME}/" test.sql
hive --hiveconf mapreduce.job.queuename=${QUEUE} -f test.sql ||
        FAILURES="${FAILURES} hive"
git co -- test.sql
hive -e "DROP TABLE qa_${HNAME}"

hdfs dfs -rm -r ${FOLDER}

for fail in ${FAILURES}
do
        echo "${fail} FAILED"
done
