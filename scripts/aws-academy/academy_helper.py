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
        if(instance_name == "setup-node"): continue;

        instance_config_info = config[instance_name]

        results[instance_name] = {
            "instance_id": instance[0]["InstanceId"],
            "dns": instance[0]["PrivateDnsName"],
            "ip": instance[0]["PrivateIpAddress"],
            "role": instance_config_info["role"]
        }

        if 'labels' in instance_config_info:
                results[instance_name]['labels'] = instance_config_info['labels']

    return results

##def test_ssh_command():
##
##    run_remote_command(
##        "ip-172-31-16-25.ec2.internal",
##        ['touch', '/home/ubuntu/test.txt']
##    )
##    pass

def setup_docker_swarm(machine_infos):
    manager_machine = None
    for name, machine_info in machine_infos.items():
        if machine_info['role'] == 'manager':
            if manager_machine is not None:
                raise Exception('More than one manager machine')
            run_remote_command(
                machine_info['dns'],
                ['docker', 'swarm', 'init', '--advertise-addr', machine_info['ip']])
            time.sleep(10)
            manager_machine = name
            join_token, _ = run_remote_command(
                machine_info['dns'],
                ['docker', 'swarm', 'join-token', '-q', 'worker'])
            join_token = join_token.strip()
    if manager_machine is None:
        raise Exception('No manager machine')
    for name, machine_info in machine_infos.items():
        if machine_info['role'] == 'worker':
            run_remote_command(
                machine_info['dns'],
                ['docker', 'swarm', 'join', '--token', join_token,
                 machine_infos[manager_machine]['ip']+':2377'])
    time.sleep(10)
    for name, machine_info in machine_infos.items():
        if 'labels' in machine_info:
            cmd = ['docker', 'node', 'update']
            for label_str in machine_info['labels']:
                cmd.extend(['--label-add', label_str])
            cmd.append(name)
            run_remote_command(machine_infos[manager_machine]['dns'], cmd)

    return 

# populate a dict with the information of ec2 machines starting with "exp-"  
def configure_machines(base_dir):

    try: 
        if os.path.exists(os.path.join(base_dir, 'machines.json')):
            raise Exception('Machines already started')

        with open(os.path.join(base_dir, 'config.json')) as fin:
            config = json.load(fin)

        machine_infos = get_available_machines(config["machines"])
        print(machine_infos)

        #test_ssh_command()
        setup_docker_swarm(machine_infos)

        with open(os.path.join(base_dir, 'machines.json'), 'w') as fout:
            json.dump(machine_infos, fout, indent=4, sort_keys=True)
    
    except Exception as e:
        disband_docker_swarm(machine_infos, base_dir)
        raise e


def disband_docker_swarm(machine_infos, base_dir):

    if os.path.exists(os.path.join(base_dir, 'docker-compose-generated.yml')):
        for name, machine_info in machine_infos.items():
            if machine_info['role'] == 'manager':
                run_remote_command(
                    machine_info['dns'],
                    ['docker', 'service', 'rm', '$(docker', 'service', 'ls', '-q)'])
        time.sleep(10)
    for name, machine_info in machine_infos.items():
        run_remote_command(
            machine_info['dns'],
            ['docker', 'swarm', 'leave', '--force'])
    return

def disband_machines(base_dir):

    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)

    disband_docker_swarm(machine_infos, base_dir)
    os.remove(os.path.join(base_dir, 'machines.json'))

    return

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
        elif args.cmd == 'disband-machines':
            disband_machines(args.base_dir)
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