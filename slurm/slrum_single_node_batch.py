import sys
from google.cloud import batch_v1
import yaml

# Constants for default values
DEFAULT_CPUS = 1
DEFAULT_GPU_COUNT = 0


def parse_slurm_script(slurm_script_path):
  """Parses a Slurm script to extract CPU, GPU count, and GPU type.

  Args:
      slurm_script_path (str): The path to a Slurm script.

  Returns:
      tuple: (cpus, gpus, gpu_type)
  """

  cpus = DEFAULT_CPUS
  gpus = DEFAULT_GPU_COUNT
  gpu_type = None
  
  try:
    with open(slurm_script_path, 'r') as f:
      slurm_script = f.read()
  except FileNotFoundError:
    print(f'Error: SLURM script file not found at {slurm_script_path}')
    sys.exit(1)
  print(slurm_script)
  for line in slurm_script.splitlines():
    line = line.strip()
    if line.startswith('#SBATCH'):
      parts = line.split()
      print(parts)

      if '--cpus-per-task' in parts[1]:
        cpus_per_task = int(parts[1].split('=')[1])
      elif '--ntasks-per-node' in parts[1]:
        ntasks_per_node = int(parts[1].split('=')[1])
      elif '--gpus-per-task' in parts[1]:
        gpus_per_task = int(parts[1].split('=')[1])
      elif '--gres' in parts[1]:
        gres_parts = parts[1].split('=')[1].split(':')
        if len(gres_parts) >= 2:
          gpu_type = gres_parts[0]  # This will always be 'gpu'
          if len(gres_parts) == 3:
            gpu_type = gres_parts[
                1
            ]  # This captures specific GPU types like 'tesla'
            gpus = int(gres_parts[2])
          elif len(gres_parts) == 2:
            gpus = int(gres_parts[1])
            
  if 'cpus_per_task' in locals() and 'ntasks_per_node' in locals():
    cpus = cpus_per_task * ntasks_per_node
  if 'gpus_per_task' in locals() and 'ntasks_per_node' in locals():
    gpus = gpus_per_task * ntasks_per_node
  
  print(cpus, gpus, gpu_type)
  return cpus, gpus, gpu_type


def generate_gres_conf(gpu_count, gpu_type):
  """Generates the content for the Slurm gres.conf file.

  Args:
      gpu_count (int): Number of GPUs.
      gpu_type (str): Type of GPU (e.g., "tesla").

  Returns:
      str: The content to be written to gres.conf
  """

  gres_conf = 'cat <<EOF > /etc/slurm/gres.conf\n# Define GPU resources\n'
  for i in range(gpu_count):
    gres_conf += (
        f'Name=gpu Type={gpu_type} File=/dev/nvidia{i}\n'
        if gpu_type
        else f'Name=gpu File=/dev/nvidia{i}\n'
    )
  gres_conf += 'EOF\n'
  return gres_conf


def generate_slurm_conf(cpu_count, gpu_count, gpu_type):
  gpu_directive = (
      f'gpu:{gpu_type}:{gpu_count}' if gpu_type else f'gpu:{gpu_count}'
  )
  return f"""
cat <<EOF >/etc/slurm/slurm.conf
SlurmctldHost=$(hostname)
AuthType=auth/munge
CryptoType=crypto/munge
ProctrackType=proctrack/cgroup
ReturnToService=1
GresTypes=gpu
SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/var/run/slurm/slurmd.pid
SlurmdPort=6818
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=root
StateSaveLocation=/var/spool/slurmctld
SwitchType=switch/none
TaskPlugin=task/none
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
SchedulerType=sched/backfill
SelectType=select/linear
AccountingStorageType=accounting_storage/none
ClusterName=cluster
SelectType=select/cons_tres 
SelectTypeParameters=CR_Core
JobAcctGatherType=jobacct_gather/cgroup
SlurmctldDebug=3
SlurmdDebug=3
NodeName=$(hostname) CPUs={cpu_count} Gres={gpu_directive} State=UNKNOWN
PartitionName=debug Nodes=$(hostname) Default=YES MaxTime=INFINITE State=UP
EOF
"""


def generate_systemd_service_conf():
  return """
cat <<EOF >/usr/lib/systemd/system/slurmctld.service
[Unit]
Description=Slurm controller daemon
After=network-online.target remote-fs.target munge.service sssd.service
Wants=network-online.target
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/slurmctld
EnvironmentFile=-/etc/default/slurmctld
User=root
Group=root
RuntimeDirectory=slurmctld
RuntimeDirectoryMode=0755
ExecStart=/sbin/slurmctld --systemd $SLURMCTLD_OPTIONS
# ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
"""


def generate_slurm_setup_script(cpus, gpus, gpu_type):
  """Generates a shell script for setting up SLURM on a Compute instance.

  Args:
      cpus (int): Number of CPUs.
      gpus (int): Number of GPUs.
      gpu_type (str): Type of GPU (e.g., "nvidia-tesla-a100").

  Returns:
      str: The shell script content.
  """
  shell_script = f"""
# Install necessary packages
yum install -y munge munge-libs munge-devel >/dev/null
echo "7d483ba99f3d95d068a054c3138ebf3822af09f6e1dd960699645643697b2134" > /etc/munge/munge.key
chown munge: /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl start munge
echo "munge started"

yum install -y rpm-build gcc python3 openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel munge munge-libs munge-devel lua lua-devel readline-devel mariadb-devel rrdtool-devel mariadb-server ncurses-devel gtk2-devel libibmad libibumad perl-Switch perl-ExtUtils-MakeMaker xorg-x11-xauth wget libssh2-devel man2html > /dev/null 2>&1

wget https://download.schedmd.com/slurm/slurm-23.11.5.tar.bz2  -q -O slurm-23.11.5.tar.bz2
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
rpmbuild -ta slurm-23.11.5.tar.bz2 > /dev/null 2>&1
yum localinstall /rpmbuild/RPMS/x86_64/slurm-*.rpm -y > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "SLURM build succeeded."
else
    echo "SLURM build failed."
fi

mkdir /etc/slurm

{generate_gres_conf(gpus, gpu_type)}

{generate_slurm_conf(cpus, gpus, gpu_type)}

mkdir /var/spool/slurm
chmod 755 /var/spool/slurm/
touch /var/log/slurmctld.log
mkdir /var/log/slurm
touch /var/log/slurm/slurmd.log /var/log/slurm/slurmctld.log
touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log

{generate_systemd_service_conf()}

nvidia-smi
sleep 1
systemctl start slurmctld
sleep 5
systemctl start slurmd
"""
  return shell_script


def create_script_job(
    project_id: str, region: str, job_name: str, slurm_script_path: str
) -> batch_v1.Job:
  """This method shows how to create a sample Batch Job that will run"""
  client = batch_v1.BatchServiceClient()
  cpus, gpus, gpu_type = parse_slurm_script(slurm_script_path)

  # Define what will be done as part of the job.
  task = batch_v1.TaskSpec()
  runnable = batch_v1.Runnable()
  runnable.script = batch_v1.Runnable.Script()
  slurm_setup = generate_slurm_setup_script(cpus, gpus, gpu_type)
  runnable.script.text = slurm_setup
  # print(slurm_setup)
  # return

  runnable_sleep = batch_v1.Runnable()
  runnable_sleep.script = batch_v1.Runnable.Script()
  runnable_sleep.script.text = 'sleep 1800'
  task.runnables = [runnable, runnable_sleep]

  group = batch_v1.TaskGroup()
  group.task_count = 1
  group.task_spec = task
  allocation_policy = create_allocation_policy(region)

  job = create_batch_job(job_name, [group], allocation_policy)
  print("YAML")
  dump_to_yaml(job)
  create_request = batch_v1.CreateJobRequest()
  create_request.job = job
  create_request.job_id = job_name
  create_request.parent = f'projects/{project_id}/locations/{region}'
  print(create_request)
  dump_to_yaml(create_request)

  # return client.create_job(create_request)
  return None


def create_allocation_policy(region):
  """Creates the AllocationPolicy object with boot disk, accelerator, and other details."""
  allocation_policy = batch_v1.AllocationPolicy()
  location_policy = batch_v1.AllocationPolicy.LocationPolicy(
      allowed_locations=[f'zones/{region}-a']
  )
  allocation_policy.location = location_policy

  accelerator = batch_v1.AllocationPolicy.Accelerator()
  accelerator.type = 'nvidia-tesla-a100'  # Or your desired accelerator type
  accelerator.count = 2  # Or the desired number of accelerators

  instance_policy = batch_v1.AllocationPolicy.InstancePolicy(
      accelerators=[accelerator]
  )

  disk = batch_v1.AllocationPolicy.Disk()
  disk.image = 'batch-centos'  # Or your desired image
  instance_policy.boot_disk = disk

  instances = batch_v1.AllocationPolicy.InstancePolicyOrTemplate(
      policy=instance_policy
  )
  instances.install_gpu_drivers = True
  allocation_policy.instances = [instances]

  return allocation_policy


def create_batch_job(job_name, task_groups, allocation_policy):
  """Creates a Batch job object with the specified details."""
  job = batch_v1.Job()
  job.task_groups = task_groups
  job.allocation_policy = allocation_policy
  job.labels = {'goog-batch-dynamic-workload-scheduler': 'true'}
  job.logs_policy = batch_v1.LogsPolicy(
      destination=batch_v1.LogsPolicy.Destination.CLOUD_LOGGING
  )
  return job

def dump_to_yaml(job):
  job_yaml = yaml.dump(vars(job), default_flow_style=False)
  print(job_yaml)
  
  


def main():
  if len(sys.argv) < 4:
    print(
        'Usage: python3 script.py <jobname> <projectID> <slurm_script_path>'
        ' [region]'
    )
    sys.exit(1)

  job_name = sys.argv[1]
  project_id = sys.argv[2]
  slurm_script_path = sys.argv[3]
  region = 'us-central1'
  if len(sys.argv) == 5:
    region = sys.argv[4]


  try:
    created_job = create_script_job(
        project_id, region, job_name, slurm_script_path
    )
    print(f'Created job: {created_job}')
  except Exception as e:
    print(f'Error creating Batch job: {e}')
    sys.exit(1)


if __name__ == '__main__':
  main()
