#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py


# create machines.json file
$ACADEMY_HELPER_SCRIPT configure-machines --base-dir=$BASE_DIR

#$BASE_DIR/run_once_academy.sh p64c64   64  6 1 64

# clean the machines up
#$ACADEMY_HELPER_SCRIPT stop-machines --base-dir=$BASE_DIR
