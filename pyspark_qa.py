from pyspark import SparkContext, SparkConf
import sys

if len(sys.argv) != 2:
    print("You must provide an input")
    sys.exit(1)

conf = SparkConf().setAppName("LineCount")
sc = SparkContext(conf=conf)

data = sc.textFile(sys.argv[1])
print(data.count())
