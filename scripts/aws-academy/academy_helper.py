#!/usr/bin/python3

import os
import sys
import time
import json
import yaml
import random
import string
import argparse
import subprocess as sp

AWS_REGION = 'us-east-1'

def run_aws_command(scope, cmd):
    ret = sp.run(['aws', '--region', AWS_REGION, '--output', 'json', scope] + cmd,
                 stdout=sp.PIPE, stderr=sp.PIPE, encoding='utf8', cwd=os.environ['HOME'])
    if ret.returncode != 0:
        raise Exception('Failed to run aws-cli command: ' + ret.stderr)
    result = ret.stdout.strip()
    return json.loads(result) if result != '' else {}

def run_aws_ec2_command(cmd):
    return run_aws_command('ec2', cmd)

def run_remote_command(ssh_str, cmd):
    ret = sp.run(['ssh', '-q', ssh_str, '--'] + cmd,
                 stdout=sp.PIPE, stderr=sp.PIPE, encoding='utf8')
    if ret.returncode != 0:
        raise Exception('Failed to run remote command: ' + ' '.join(cmd) + '\n' + ret.stderr)
    return ret.stdout, ret.stderr

def get_available_machines(config):
    results = {}

    available_instances = run_aws_ec2_command(
        ["describe-instances", 
         "--query", 
         'Reservations[*].Instances[*].{"InstanceId":InstanceId,"PrivateDnsName":PrivateDnsName,"PrivateIpAddress":PrivateIpAddress,"Tags":Tags[*]}',
         "--filters",
         "Name=instance-state-name,Values=running"
        ]
    )
    
    for instance in available_instances:
        
        instance_name = instance[0]['Tags'][0]['Value']
        print(instance_name)

        instance_config_info = config[instance_name]
        print(instance_config_info)

        results[instance_name] = {
            "instance_id": instance[0]["InstanceId"],
            "dns": instance[0]["PrivateDnsName"],
            "ip": instance[0]["PrivateIpAddress"],
            "role": instance_config_info["role"]
        }

    return results

# populate a dict with the information of ec2 machines starting with "exp-"  
def configure_machines(base_dir):

    if os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines already started')
    
    with open(os.path.join(base_dir, 'config.json')) as fin:
        config = json.load(fin)
    
    machine_info = get_available_machines(config["machines"])


    

#def parse_config():
#    with open(os.path.join(base_dir, 'config.json')) as fin:
#        config = json.load(fin)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('cmd', type=str)
    parser.add_argument('--base-dir', type=str, default='.')
    parser.add_argument('--machine-name', type=str, default=None)
    parser.add_argument('--machine-label', type=str, default=None)
    parser.add_argument('--machine-host', type=str, default=None)
    parser.add_argument('--service', type=str, default=None)
    parser.add_argument('--spot-instances-waiting-time', type=int, default=10)
    parser.add_argument('--instance-iam-role', type=str, default=None)
    parser.add_argument('--log-path', type=str, default=None)
    args = parser.parse_args()
    try:
        if args.cmd == 'configure-machines':
            configure_machines(args.base_dir)
        #elif args.cmd == 'stop-machines':
        #    stop_machines_main(args.base_dir)
        #elif args.cmd == 'generate-docker-compose':
        #    generate_docker_compose_main(args.base_dir)
        #elif args.cmd == 'get-host':
        #    get_host_main(args.base_dir, args.machine_name)
        #elif args.cmd == 'get-service-host':
        #    get_service_host_main(args.base_dir, args.service)
        #elif args.cmd == 'get-docker-manager-host':
        #    get_docker_manager_host_main(args.base_dir)
        #elif args.cmd == 'get-client-host':
        #    get_client_host_main(args.base_dir)
        #elif args.cmd == 'get-all-server-hosts':
        #    get_all_server_hosts_main(args.base_dir)
        #elif args.cmd == 'get-machine-with-label':
        #    get_machine_with_label_main(args.base_dir, args.machine_label)
        #elif args.cmd == 'get-container-id':
        #    get_container_id_main(args.base_dir, args.service, args.machine_name, args.machine_host)
        #elif args.cmd == 'collect-container-logs':
        #    collect_container_logs_main(args.base_dir, args.log_path)
        else:
            raise Exception('Unknown command: ' + args.cmd)
    except Exception as e:
        err_str = str(e)
        if not err_str.endswith('\n'):
            err_str += '\n'
        sys.stderr.write(err_str)
        sys.exit(1)