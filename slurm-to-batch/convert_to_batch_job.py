import os
import json
import yaml
import sys
from slurm_script_parser import SlurmJobConfig, SlurmScriptParser


def generate_gres_conf_script(slurm_config: SlurmJobConfig):
    gres_conf_script = f"""#!/bin/bash

# Script to configure Slurm's GPU resources in gres.conf

cat <<EOF > /usr/local/etc/slurm/gres.conf
# Define GPU resources
AutoDetect=nvml
"""
    if slurm_config.gpu_per_node > 0 and slurm_config.gpu_type not in ["None", None, ""]:
        for i in range(slurm_config.gpu_per_node):
            gres_conf_script += f"Name=gpu Type={slurm_config.gpu_type} File=/dev/nvidia{i}\n"
    else:
        for i in range(slurm_config.gpu_per_node):
            gres_conf_script += f"Name=gpu File=/dev/nvidia{i}\n"

    gres_conf_script += "EOF\n"
    return gres_conf_script

def generate_slurm_conf_script(slurm_config: SlurmJobConfig) -> str:
    node_count = slurm_config.node_count

    slurm_conf_script_fixed = """

cat <<EOF > /usr/local/etc/slurm/slurm.conf
ClusterName=${BATCH_JOB_ID}
SlurmctldHost=$(head -1 ${BATCH_HOSTS_FILE})
AuthType=auth/munge

ProctrackType=proctrack/pgid
ReturnToService=2

# For GPU resource
GresTypes=gpu

SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmdPidFile=/var/run/slurm/slurmd.pid
# slurm logs
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdSpoolDir=/var/spool/slurmd

SlurmUser=root
StateSaveLocation=/var/spool/slurmctld
TaskPlugin=task/none
SchedulerType=sched/backfill
SelectTypeParameters=CR_Core

# Turn off both types of accounting
JobAcctGatherFrequency=0
JobAcctGatherType=jobacct_gather/none
AccountingStorageType=accounting_storage/none

SlurmctldDebug=3
SlurmdDebug=3
SelectType=select/cons_tres
"""

    slurm_conf_script_not_fixed = f"MaxNodeCount={node_count}\nPartitionName=all  Nodes=ALL Default=yes\nEOF"
    return slurm_conf_script_fixed + slurm_conf_script_not_fixed


def start_slurmctld() -> str: 
    return f"""

mkdir -p /var/spool/slurm
chmod 755 /var/spool/slurm/
touch /var/log/slurmctld.log
mkdir -p /var/log/slurm
touch /var/log/slurm/slurmd.log /var/log/slurm/slurmctld.log
touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log

rm -rf /var/spool/slurmctld/*
if [[ "$BATCH_NODE_INDEX" == "0" ]]; then
    systemctl start slurmctld
    MAX_RETRIES=5
    RETRY_INTERVAL=5
    for (( i=1; i<=MAX_RETRIES; i++ )); do
        if systemctl is-active --quiet slurmctld; then
        echo "slurmctld are running."
        break
        fi
        echo "Services not running. Retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
    done
fi
"""

def start_slurmd(slurm_config:SlurmJobConfig) -> str:
    gpu_per_node = slurm_config.gpu_per_node
    return f"""#!/bin/bash

/usr/local/sbin/slurmd -Z --conf "Gres=gpu:{gpu_per_node}"
RETRIES=5
WAIT_TIME=1

for (( i=1; i<=$RETRIES; i++ )); do
    if ps -ef | grep -v grep | grep slurmd > /dev/null; then
        echo "slurmd is running!"
        exit 0
    else
        echo "slurmd not found, retrying in $WAIT_TIME seconds..."
        sleep $WAIT_TIME
    fi
done

echo "slurmd did not start after $RETRIES attempts."
exit 1
"""

def work_load() -> str:
    return """#!/bin/bash

if [[ "$BATCH_NODE_INDEX" == "0" ]]; then
    <SRUN_COMMAND>
fi
"""

def createJobJSON(slurm_conf: SlurmJobConfig) -> dict:
    slurm_setup = generate_gres_conf_script(slurm_conf) + generate_slurm_conf_script(slurm_conf) + start_slurmctld()
    job_definition = {
        "taskGroups": [
            {
                "task_spec": {
                    "runnables": [
                        {
                            "script": {
                                "text": slurm_setup,
                            },
                        },
                        {
                            "barrier": {}
                        },
                        {
                            "script": {
                                "text": start_slurmd(slurm_conf)
                            }
                        },
                        {
                            "barrier": {}
                        },
                        {
                            "script": {
                                "text": work_load()
                            }
                        },
                        {
                            "barrier": {}
                        },
                    ],
                },
                "task_count_per_node": 1,
                "task_count": slurm_conf.node_count,
                "require_hosts_file": True
            }
        ],
        "allocation_policy": {
            "location": {
                "allowed_locations": ["zones/<SELECTED_ZONE>"]
            },
            "instances": {
                "policy": {
                    "accelerators": {
                        "type": "<CUSTOM_GPU_TYPE>",
                        "count": slurm_conf.gpu_per_node
                    },
                    "boot_disk": {
                        "image": "<CUSTOM_BOOT_IMAGE>",
                        "size_gb": "<CUSTOM_BOOT_DISK_SIZE>",
                    }
                },
                "install_gpu_drivers": True
            }
        },
        "labels": {
            "goog-batch-dynamic-workload-scheduler": "true"
        },
        "logs_policy": {
            "destination": "CLOUD_LOGGING"
        }
    }
    return job_definition

def main():
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print(
            'Usage: python3 convert_slurm_batch_job.py <slurm_script_path> <batch_template_folder>(optional)'
        )
        sys.exit(1)
        

    slurm_script_path = sys.argv[1]
    if len(sys.argv) == 2:
        # Use the slurm_script_path's folder.
        output_dir = os.path.dirname(slurm_script_path)
    else:
        output_dir = sys.argv[2]
    os.makedirs(output_dir, exist_ok=True)
    
    config = SlurmScriptParser.parse_slurm_script(slurm_script_path)
    json_data = json.dumps(createJobJSON(config), indent=4)
    json_file_path = os.path.join(output_dir, f"{config.job_name}_template.json")
    with open(json_file_path, 'w') as json_file:
        json_file.write(json_data)

    def str_presenter(dumper, data):
        """configures yaml for dumping multiline strings
        Ref: https://stackoverflow.com/questions/8640959/how-can-i-control-what-scalar-form-pyyaml-uses-for-my-data"""
        if data.count('\n') > 0:  # check for multiline string
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
        return dumper.represent_scalar('tag:yaml.org,2002:str', data)
    yaml.add_representer(str, str_presenter)
    yaml.representer.SafeRepresenter.add_representer(str, str_presenter)
    yaml_data = yaml.dump(createJobJSON(config), allow_unicode=True)
    yaml_file_path = os.path.join(output_dir, f"{config.job_name}_template.yaml")
    with open(yaml_file_path, 'w', encoding='utf-8') as file:
        file.write(yaml_data)

if __name__ == '__main__':
  main()