#!/bin/bash

if [ ! -d ~/monitoring ]
  then mkdir ~/monitoring
fi

cdate=$(date '+%H-%M-%S-%N')
mkdir -p ~/monitoring/$1

freefd=~/monitoring/$1/free.out
iostatfd=~/monitoring/$1/iostat.out

touch $freefd
touch $iostatfd

sleep 10

for i in {1..20}
do
    #echo "LOOP: $i | " >> /home/ubuntu/marking
    dt=$(date +"%D %S %N")

    # free 
    echo "-- LOOP $i | $dt" >> $freefd
    free -h >> $freefd

    # iostat
    echo "-- LOOP $i | $dt" >> $iostatfd
    iostat -h >> $iostatfd

    sleep 10
done