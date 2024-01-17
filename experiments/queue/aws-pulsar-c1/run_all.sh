#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py

echo "Running configure-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

#$BASE_DIR/run_once.sh p64c64   6 64  64
#$BASE_DIR/run_once.sh p128c128 6 128 128
#$BASE_DIR/run_once.sh p256c256 8 256 256
echo "Running run_once_academy.sh 64 16"
$BASE_DIR/run_once.sh p256c256 8 64 16
echo "Running run_once_academy.sh 16 64"
$BASE_DIR/run_once.sh p256c256 8 16 64
echo "Running run_once_academy.sh 64 64"
$BASE_DIR/run_once.sh p256c256 8 64 64

#$BASE_DIR/run_once.sh p64c16  7  64  16
#$BASE_DIR/run_once.sh p128c32 8  128 32
#$BASE_DIR/run_once.sh p256c64 12 256 64

#$BASE_DIR/run_once.sh p16c64  3 16 64
#$BASE_DIR/run_once.sh p32c128 3 32 128
#$BASE_DIR/run_once.sh p64c256 4 64 256

echo "Running disband-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT disband-machines --base-dir=$BASE_DIR
