CREATE TABLE trozamon_testing_ngrams_HOSTNAME_THINGY
(ngram STRING, year INT, count BIGINT, volumes BIGINT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';

LOAD DATA INPATH 'trozamon_testingHOSTNAME_THINGY/input_structured'
OVERWRITE INTO TABLE trozamon_testing_ngrams_HOSTNAME_THINGY;

SELECT COUNT(*) FROM trozamon_testing_ngrams_HOSTNAME_THINGY;

DROP TABLE trozamon_testing_ngrams_HOSTNAME_THINGY;
