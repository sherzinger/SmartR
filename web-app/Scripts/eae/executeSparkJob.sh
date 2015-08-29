#!/usr/bin/env bash

pdsh -W $1 "spark-submit --py-files CrossValidation.zip --master yarn-cluster  --num-executors 2 --driver-memory 1024m  --executor-memory 512m   --executor-cores 1" + $0 # We trigger the Spark Job
