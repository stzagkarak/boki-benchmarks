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
ipslinkfd=~/monitoring/$1/ipslink.out

touch $freefd
touch $iostatfd
touch $mpstatfd
touch $pidstatfd
touch $ipslinkfd

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
    mpstat >> $mpstatfd

    # pidstat
    echo "-- LOOP $i | $dt" >> $pidstatfd
    pidstat -h >> $pidstatfd

    # ipslinkfd
    echo "-- LOOP $i | $dt" >> $ipslinkfd
    ip -s link >> $ipslinkfd

    sleep 20
done

sleep 5