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

# populate a dict with the information of ec2 machines starting with "exp-"  
def parse_ec2_machines(config):
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

        instance_config_info = config["machines"][instance['Tags']['Value']]

        results[instance['Tags']['Value']] = {
            "instance_id": instance["InstanceId"],
            "dns": instance["PrivateDnsName"],
            "ip": instance["PrivateIpAddress"],
            "role": instance_config_info["role"]
        }

    return results

parse_ec2_machines()