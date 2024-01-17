#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_DIR=$BASE_DIR/results/$1

INTERVAL=$2
NUM_PRODUCER=$3
NUM_CONSUMER=$4

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py

echo "Running getting hosts on ACADEMY_HELPER_SCRIPT"
MANAGER_HOST=`$ACADEMY_HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$ACADEMY_HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$ACADEMY_HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`
ALL_HOSTS=`$ACADEMY_HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR`

$ACADEMY_HELPER_SCRIPT generate-docker-compose --base-dir=$BASE_DIR
scp -q $BASE_DIR/docker-compose.yml $MANAGER_HOST:~
scp -q $BASE_DIR/docker-compose-generated.yml $MANAGER_HOST:~

echo "Running generate-docker-compose on ACADEMY_HELPER_SCRIPT"
ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

sleep 40

echo "Copying -- zk_setup.sh on MANAGER_HOST"
scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh

echo "Copying -- nightcore and pulsar config on ALL_HOSTS"
for host in $ALL_HOSTS; do
    scp -q $BASE_DIR/nightcore_config.json $host:/tmp/nightcore_config.json
    ssh -q $host sudo rm -rf /tmp/pulsar
    ssh -q $host mkdir /tmp/pulsar
    scp -qr $BASE_DIR/conf $host:/tmp/pulsar
done

echo "Executing -- ... on ALL_ENGINE_HOSTS"
ALL_ENGINE_HOSTS=`$ACADEMY_HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
for HOST in $ALL_ENGINE_HOSTS; do
    scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
    ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
    ssh -q $HOST -- sudo cp /tmp/nightcore_config.json /mnt/inmem/boki/func_config.json
done

echo "Executing -- (storage setup staff) on ALL_STORAGE_HOSTS"
ALL_STORAGE_HOSTS=`$ACADEMY_HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
for HOST in $ALL_STORAGE_HOSTS; do
    ssh -q $HOST -- sudo rm -rf   /mnt/storage/pulsar
    ssh -q $HOST -- sudo mkdir -p /mnt/storage/pulsar
done

echo "Executing -- docker stack deploy on MANAGER_HOST"
ssh -q $MANAGER_HOST -- docker stack deploy \
    -c /home/ubuntu/docker-compose-generated.yml -c /home/ubuntu/docker-compose.yml boki-experiment

echo "Sleeping for 60 secs"
sleep 60

#for HOST in $ALL_ENGINE_HOSTS; do
#    ENGINE_CONTAINER_ID=`$ACADEMY_HELPER_SCRIPT get-container-id --base-dir=$BASE_DIR --service faas-engine --machine-host $HOST`
#    echo 4096 | ssh -q $HOST -- sudo tee /sys/fs/cgroup/cpu,cpuacct/docker/$ENGINE_CONTAINER_ID/cpu.shares
#done

echo "Sleeping for 10 secs"
sleep 10

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

echo "Executing -- docker run ( to copy benchmark ) on CLIENT_HOST"
ssh -q $CLIENT_HOST -- docker run -v /tmp:/tmp \
    zjia/boki-queuebench:sosp-ae \
    cp /queuebench-bin/benchmark /tmp/benchmark

echo "Starting -- benchmark on CLIENT_HOST"
ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 --fn_prefix=pulsar \
    --queue_prefix=global --num_queues=1 \
    --num_producer=$NUM_PRODUCER --num_consumer=$NUM_CONSUMER \
    --producer_interval=$INTERVAL --consumer_interval=0 \
    --payload_size=1024 --duration=180 >$EXP_DIR/results.log

$ACADEMY_HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
