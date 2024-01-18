#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py


# create machines.json file
echo "Running configure-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

echo "Running run_once_academy.sh p64c16 64 3 1 16"
$BASE_DIR/run_once_academy.sh p64c16_1 64 3 1 16
$BASE_DIR/run_once_academy.sh p64c16_2 64 3 1 16
$BASE_DIR/run_once_academy.sh p64c16_3 64 3 1 16
$BASE_DIR/run_once_academy.sh p64c16_4 64 3 1 16
$BASE_DIR/run_once_academy.sh p64c16_5 64 3 1 16

echo "Running run_once_academy.sh p16c64 16 8 1 64"
$BASE_DIR/run_once_academy.sh p16c64_1 16 8  1 64
$BASE_DIR/run_once_academy.sh p16c64_2 16 8  1 64
$BASE_DIR/run_once_academy.sh p16c64_3 16 8  1 64
$BASE_DIR/run_once_academy.sh p16c64_4 16 8  1 64
$BASE_DIR/run_once_academy.sh p16c64_5 16 8  1 64

echo "Running run_once_academy.sh p64c64 64 6 1 64"
$BASE_DIR/run_once_academy.sh p64c64_1 64 6 1 64
$BASE_DIR/run_once_academy.sh p64c64_2 64 6 1 64
$BASE_DIR/run_once_academy.sh p64c64_3 64 6 1 64
$BASE_DIR/run_once_academy.sh p64c64_4 64 6 1 64
$BASE_DIR/run_once_academy.sh p64c64_5 64 6 1 64

# clean the machines up
echo "Running disband-machines on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT disband-machines --base-dir=$BASE_DIR
