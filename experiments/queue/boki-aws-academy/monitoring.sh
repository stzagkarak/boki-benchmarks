#!/bin/bash

if [ ! -d ~/monitoring ]
  then mkdir ~/monitoring
fi

rm -rf ~/monitoring/$1
mkdir -p ~/monitoring/$1

freefd=~/monitoring/$1/free.out
iostatfd=~/monitoring/$1/iostat.out
mpstatfd=~/monitoring/$1/mpstat.out
pidstatfd=~/monitoring/$1/pidstat.out
cifsiostatfd=~/monitoring/$1/cifsiostat.out

touch $freefd
touch $iostatfd
touch $mpstatfd
touch $pidstatfd
touch $cifsiostatfd

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

    # mpstat 
    echo "-- LOOP $i | $dt" >> $mpstatfd
    mpstat -h >> $mpstatfd

    # pidstat
    echo "-- LOOP $i | $dt" >> $pidstatfd
    pidstat -h >> $pidstatfd

    # cifsiostat
    echo "-- LOOP $i | $dt" >> $cifsiostatfd
    cifsiostat -h >> $cifsiostatfd

    sleep 10
done