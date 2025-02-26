#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py


# create machines.json file
echo "Running configure-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

echo "Running run_once_academy.sh p128c32 128 3 1 32"
$BASE_DIR/run_once_academy.sh p128c32_1 128 3 1 32
$BASE_DIR/run_once_academy.sh p128c32_2 128 3 1 32
$BASE_DIR/run_once_academy.sh p128c32_3 128 3 1 32
$BASE_DIR/run_once_academy.sh p128c32_4 128 3 1 32
$BASE_DIR/run_once_academy.sh p128c32_5 128 3 1 32

echo "Running run_once_academy.sh p32c128 32 8 1 128"
$BASE_DIR/run_once_academy.sh p32c128_1 32 8  1 128
$BASE_DIR/run_once_academy.sh p32c128_2 32 8  1 128
$BASE_DIR/run_once_academy.sh p32c128_3 32 8  1 128
$BASE_DIR/run_once_academy.sh p32c128_4 32 8  1 128
$BASE_DIR/run_once_academy.sh p32c128_5 32 8  1 128

echo "Running run_once_academy.sh p128c128 128 6 1 128"
$BASE_DIR/run_once_academy.sh p128c128_1 128 6 1 128
$BASE_DIR/run_once_academy.sh p128c128_2 128 6 1 128
$BASE_DIR/run_once_academy.sh p128c128_3 128 6 1 128
$BASE_DIR/run_once_academy.sh p128c128_4 128 6 1 128
$BASE_DIR/run_once_academy.sh p128c128_5 128 6 1 128

# clean the machines up
echo "Running disband-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT disband-machines --base-dir=$BASE_DIR
