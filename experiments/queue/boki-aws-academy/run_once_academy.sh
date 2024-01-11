echo "Running run_once_academy.sh"

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_DIR=$BASE_DIR/results/$1

NUM_SHARDS=$2
INTERVAL1=$3
INTERVAL2=$4
NUM_PRODUCER=$5
NUM_CONSUMER=$NUM_SHARDS

ACADEMY_HELPER_SCRIPT=$ROOT_DIR/scripts/aws-academy/academy_helper.py

echo "Running get-docker-manager-host on ACADEMY_HELPER_SCRIPT"
MANAGER_HOST=`$ACADEMY_HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
echo "Running get-client-host on ACADEMY_HELPER_SCRIPT"
CLIENT_HOST=`$ACADEMY_HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
echo "Running get-service-host on ACADEMY_HELPER_SCRIPT"
ENTRY_HOST=`$ACADEMY_HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`
echo "Running get-all-server-hosts on ACADEMY_HELPER_SCRIPT"
ALL_HOSTS=`$ACADEMY_HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR`

echo "Running generate-docker-compose on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT generate-docker-compose --base-dir=$BASE_DIR
scp -q $BASE_DIR/docker-compose.yml $MANAGER_HOST:~
scp -q $BASE_DIR/docker-compose-generated.yml $MANAGER_HOST:~

echo "Executing -- docker stack rm on MANAGER_HOST"
ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

echo "Sleeping for 40 secs"
sleep 40

echo "Copying -- zk_setup.sh on MANAGER_HOST"
scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh

echo "Copying -- nightcore_config.sh on ALL_HOSTS"
for host in $ALL_HOSTS; do
    scp -q $BASE_DIR/nightcore_config.json $host:/tmp/nightcore_config.json
done

echo "Running -- get-machine-with-label (engine_node) on ACADEMY_HELPER_SCRIPT"
ALL_ENGINE_HOSTS=`$ACADEMY_HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

echo "Executing -- ... on ALL_ENGINE_HOSTS"
for HOST in $ALL_ENGINE_HOSTS; do
    scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
    ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
    ssh -q $HOST -- sudo cp /tmp/nightcore_config.json /mnt/inmem/boki/func_config.json
done

echo "Running -- get-machine-with-label (engine_node) on ALL_STORAGE_HOSTS"
ALL_STORAGE_HOSTS=`$ACADEMY_HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`

echo "Executing -- (storage setup staff) on ALL_STORAGE_HOSTS"
for HOST in $ALL_STORAGE_HOSTS; do
    ssh -q $HOST -- sudo rm -rf   /mnt/storage/logdata
    ssh -q $HOST -- sudo mkdir -p /mnt/storage/logdata
done

echo "Executing -- docker stack deploy on MANAGER_HOST"
ssh -q $MANAGER_HOST -- docker stack deploy \
    -c /home/ubuntu/docker-compose-generated.yml -c /home/ubuntu/docker-compose.yml boki-experiment

echo "Sleeping for 60 secs"
sleep 60

#echo "Optimizing docker on ALL_ENGINE_HOSTS"
#for HOST in $ALL_ENGINE_HOSTS; do
#    ENGINE_CONTAINER_ID=`$ACADEMY_HELPER_SCRIPT get-container-id --base-dir=$BASE_DIR --service faas-engine --machine-host $HOST`
#    echo 4096 | ssh -q $HOST -- sudo tee /sys/fs/cgroup/cpu,cpuacct/docker/$ENGINE_CONTAINER_ID/cpu.shares
#done

QUEUE_PREFIX=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

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

echo "Preparing -- monitoring script on ALL_HOSTS"
for HOST in $ALL_HOSTS; do
    scp -q $BASE_DIR/monitoring.sh $HOST:/home/ubuntu/monitoring.sh
done

echo "Running -- monitoring script $EXP_IDENTIFIER on ALL_HOSTS"
for HOST in $ALL_HOSTS; do
    ssh -q $HOST -- /home/ubuntu/monitoring.sh $1
done

echo "Starting -- benchmark on CLIENT_HOST"
ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 --fn_prefix=slib \
    --queue_prefix=$QUEUE_PREFIX --num_queues=1 --queue_shards=$NUM_SHARDS \
    --num_producer=$NUM_PRODUCER --num_consumer=$NUM_CONSUMER \
    --producer_interval=$INTERVAL1 --consumer_interval=$INTERVAL2 \
    --consumer_fix_shard=true \
    --payload_size=1024 --duration=180 >$EXP_DIR/results.log

echo "Running -- collect-container-logs on ACADEMY_HELPER_SCRIPT"
$ACADEMY_HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs

echo "Collecting monitoring logs from ALL_HOSTS"
for HOST in $ALL_HOSTS; do
    mkdir -p $EXP_DIR/monitoring/$HOST
    scp -q $HOST:/home/ubuntu/monitoring/$1 $EXP_DIR/monitoring/$HOST
    ssh -q $HOST -- rm -rf /home/ubuntu/monitoring/$1
done
