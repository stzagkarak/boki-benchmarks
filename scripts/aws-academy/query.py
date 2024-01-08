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
        print(reservation)
        for instance in reservation:
            print(instance)

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

with open(os.path.join("/home/ec2-user/boki-benchmarks/experiments/queue/boki-aws-academy", 'config.json')) as fin:
            config = json.load(fin)
res = get_available_machines(config)

print(res)