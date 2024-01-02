BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_DIR=$BASE_DIR/results/$1

NUM_SHARDS=$2
INTERVAL1=$3
INTERVAL2=$4
NUM_PRODUCER=$5
NUM_CONSUMER=$NUM_SHARDS

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws_academy/academy_helper.py

MANAGER_HOST=`$ACADEMY_HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$ACADEMY_HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$ACADEMY_HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`
ALL_HOSTS=`$ACADEMY_HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR`