#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py

echo "Running configure-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

echo "Running run_once_academy.sh 128 32"
$BASE_DIR/run_once.sh p128c32_1 8 128 32
$BASE_DIR/run_once.sh p128c32_2 8 128 32
$BASE_DIR/run_once.sh p128c32_3 8 128 32
$BASE_DIR/run_once.sh p128c32_4 8 128 32
$BASE_DIR/run_once.sh p128c32_5 8 128 32
echo "Running run_once_academy.sh 32 128"
$BASE_DIR/run_once.sh p32c128_1 8 32 128
$BASE_DIR/run_once.sh p32c128_2 8 32 128
$BASE_DIR/run_once.sh p32c128_3 8 32 128
$BASE_DIR/run_once.sh p32c128_4 8 32 128
$BASE_DIR/run_once.sh p32c128_5 8 32 128
echo "Running run_once_academy.sh 128 128"
$BASE_DIR/run_once.sh p128c128_1 8 128 128
$BASE_DIR/run_once.sh p128c128_2 8 128 128
$BASE_DIR/run_once.sh p128c128_3 8 128 128
$BASE_DIR/run_once.sh p128c128_4 8 128 128
$BASE_DIR/run_once.sh p128c128_5 8 128 128

echo "Running disband-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT disband-machines --base-dir=$BASE_DIR
