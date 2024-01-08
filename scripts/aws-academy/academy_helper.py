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
    
    for reservation in available_instances:
        for instance in reservation:

            instance_name = instance['Tags'][0]['Value']
            if(instance_name == "setup-node"): continue;

            instance_config_info = config[instance_name]

            results[instance_name] = {
                "instance_id": instance["InstanceId"],
                "dns": instance["PrivateDnsName"],
                "ip": instance["PrivateIpAddress"],
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

        setup_docker_swarm(machine_infos)
        setup_instance_storage(config["machines"], machine_infos)

        with open(os.path.join(base_dir, 'machines.json'), 'w') as fout:
            json.dump(machine_infos, fout, indent=4, sort_keys=True)
    
    except Exception as e:
        disband_docker_swarm(machine_infos, base_dir)
        raise e

def setup_instance_storage(machine_configs, machine_infos):
    for name, machine_config in machine_configs.items():
        if 'mount_instance_storage' in machine_config:
            dns = machine_infos[name]['dns']
            device = '/dev/' + machine_config['mount_instance_storage']
            run_remote_command(dns, ['sudo', 'mkfs', '-t', 'ext4', device])
            run_remote_command(dns, ['sudo', 'mkdir', '/mnt/storage'])
            run_remote_command(dns, ['sudo', 'mount', '-o', 'defaults,noatime', device, '/mnt/storage'])

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

def get_host_main(base_dir, machine_name):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    print(machine_infos[machine_name]['dns'])

def get_service_host_main(base_dir, service_name):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'config.json')) as fin:
        config = json.load(fin)
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    machine = config['services'][service_name]['placement']
    print(machine_infos[machine]['dns'])

def get_docker_manager_host_main(base_dir):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    for machine_info in machine_infos.values():
        if machine_info['role'] == 'manager':
            print(machine_info['dns'])
            break

def get_client_host_main(base_dir):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    for machine_info in machine_infos.values():
        if machine_info['role'] == 'client':
            print(machine_info['dns'])
            break

def get_all_server_hosts_main(base_dir):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    for machine_info in machine_infos.values():
        if machine_info['role'] != 'client':
            print(machine_info['dns'])

def get_machine_with_label_main(base_dir, label):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'config.json')) as fin:
        config = json.load(fin)
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    for name, machine_info in machine_infos.items():
        if 'labels' in config['machines'][name]:
            labels = config['machines'][name]['labels']
            if label in labels or label+'=true' in labels:
                print(machine_info['dns'])

def get_container_id_main(base_dir, service_name, machine_name, machine_host):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    if machine_host is None:
        if machine_name is None:
            with open(os.path.join(base_dir, 'config.json')) as fin:
                config = json.load(fin)
            machine_name = config['services'][service_name]['placement']
        machine_host = machine_infos[machine_name]['dns']
    short_id, _ = run_remote_command(machine_host,
                                     ['docker', 'ps', '-q', '-f', 'name='+service_name])
    short_id = short_id.strip()
    if short_id != '':
        container_info, _ = run_remote_command(machine_host, ['docker', 'inspect', short_id])
        container_info = json.loads(container_info)[0]
        print(container_info['Id'])

def generate_docker_compose_main(base_dir):
    with open(os.path.join(base_dir, 'config.json')) as fin:
        config = json.load(fin)
    docker_compose = { 'version': '3.8', 'services': {} }
    for name, service_config in config['services'].items():
        docker_compose['services'][name] = { 'deploy': {} }
        service_docker_compose = docker_compose['services'][name]
        service_docker_compose['deploy']['replicas'] = service_config.get('replicas', 1)
        if 'placement' in service_config:
            service_docker_compose['deploy']['placement'] = {
                'constraints': ['node.hostname == %s' % (service_config['placement'],)]
            }
        elif 'placement_label' in service_config:
            service_docker_compose['deploy']['placement'] = {
                'constraints': ['node.labels.%s == true' % (service_config['placement_label'],)],
                'max_replicas_per_node': 1
            }
        service_docker_compose['environment'] = []
        service_docker_compose['volumes'] = []
        if 'need_aws_env' in service_config and service_config['need_aws_env']:
            if 'aws_access_key_id' in config:
                service_docker_compose['environment'].append(
                    'AWS_ACCESS_KEY_ID=%s' % (config['aws_access_key_id'],))
            if 'aws_secret_access_key' in config:
                service_docker_compose['environment'].append(
                    'AWS_SECRET_ACCESS_KEY=%s' % (config['aws_secret_access_key'],))
            if 'aws_region' in config:
                service_docker_compose['environment'].append(
                    'AWS_REGION=%s' % (config['aws_region'],))
        if 'mount_certs' in service_config and service_config['mount_certs']:
            service_docker_compose['volumes'].append(
                '/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt')
    with open(os.path.join(base_dir, 'docker-compose-generated.yml'), 'w') as fout:
        yaml.dump(docker_compose, fout, default_flow_style=False)

def collect_container_logs_main(base_dir, log_path):
    if not os.path.exists(os.path.join(base_dir, 'machines.json')):
        raise Exception('Machines not started')
    os.makedirs(log_path, exist_ok=True)
    with open(os.path.join(base_dir, 'machines.json')) as fin:
        machine_infos = json.load(fin)
    for machine_info in machine_infos.values():
        if machine_info['role'] == 'client':
            continue
        container_ids, _ = run_remote_command(machine_info['dns'], ['docker', 'ps', '-q'])
        container_ids = container_ids.strip().split()
        for container_id in container_ids:
            container_info, _ = run_remote_command(
                machine_info['dns'], ['docker', 'inspect', container_id])
            container_info = json.loads(container_info)[0]
            container_name = container_info['Name'][1:]  # remove prefix '/'
            log_stdout, log_stderr = run_remote_command(
                machine_info['dns'], ['docker', 'container', 'logs', container_id])
            with open(os.path.join(log_path, '%s.stdout' % container_name), 'w') as fout:
                fout.write(log_stdout)
            with open(os.path.join(log_path, '%s.stderr' % container_name), 'w') as fout:
                fout.write(log_stderr)

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
        elif args.cmd == 'generate-docker-compose':
            generate_docker_compose_main(args.base_dir)
        elif args.cmd == 'get-host':
            get_host_main(args.base_dir, args.machine_name)
        elif args.cmd == 'get-service-host':
            get_service_host_main(args.base_dir, args.service)
        elif args.cmd == 'get-docker-manager-host':
            get_docker_manager_host_main(args.base_dir)
        elif args.cmd == 'get-client-host':
            get_client_host_main(args.base_dir)
        elif args.cmd == 'get-all-server-hosts':
            get_all_server_hosts_main(args.base_dir)
        elif args.cmd == 'get-machine-with-label':
            get_machine_with_label_main(args.base_dir, args.machine_label)
        elif args.cmd == 'get-container-id':
            get_container_id_main(args.base_dir, args.service, args.machine_name, args.machine_host)
        elif args.cmd == 'collect-container-logs':
            collect_container_logs_main(args.base_dir, args.log_path)
        else:
            raise Exception('Unknown command: ' + args.cmd)
    except Exception as e:
        err_str = str(e)
        if not err_str.endswith('\n'):
            err_str += '\n'
        sys.stderr.write(err_str)
        sys.exit(1)