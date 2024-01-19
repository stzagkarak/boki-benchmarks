#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py

echo "Running configure-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

echo "1 Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p64c16_1 8 64 16
echo "2 Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p64c16_2 8 64 16
echo "3 Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p64c16_3 8 64 16
echo "4 Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p64c16_4 8 64 16
echo "5 Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p64c16_5 8 64 16

echo "6 Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p16c64_1 8 16 64
echo "7 Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p16c64_2 8 16 64
echo "8 Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p16c64_3 8 16 64
echo "9 Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p16c64_4 8 16 64
echo "10 Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p16c64_5 8 16 64

echo "11 Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p64c64_1 8 64 64
echo "12 Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p64c64_2 8 64 64
echo "13 Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p64c64_3 8 64 64
echo "14 Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p64c64_4 8 64 64
echo "15 Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p64c64_5 8 64 64

echo "Running disband-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT disband-machines --base-dir=$BASE_DIR
