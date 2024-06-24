import re

class SlurmJobConfig:
    def __init__(self, job_name, node_count, total_cpus, total_gpus, gpu_type, total_tasks):
        self.job_name = job_name
        self.node_count = node_count
        self.total_cpus = total_cpus
        self.total_gpus = total_gpus
        self.gpu_type = gpu_type if gpu_type else "None"
        self.total_tasks = total_tasks
        
        self.cpu_per_node = total_cpus // node_count
        self.gpu_per_node = total_gpus // node_count

    def __str__(self):
        return (f"Job Name: {self.job_name}\n"
                f"Total Nodes: {self.node_count}\n"
                f"Total CPUs: {self.total_cpus}\n"
                f"Total GPUs: {self.total_gpus}\n"
                f"GPU Type: {self.gpu_type}\n"
                f"Total Tasks: {self.total_tasks}")

class SlurmScriptParser:
    @staticmethod
    def parse_slurm_script(file_path: str) -> SlurmJobConfig:
        with open(file_path, 'r') as file:
            content = file.read()

        job_name = re.search(r'#SBATCH\s+--job-name=(\S+)', content)
        cpus_per_task = re.search(r'#SBATCH\s+--cpus-per-task=(\d+)', content)
        gpus_per_task = re.search(r'#SBATCH\s+--gpus-per-task=(\d+)', content)
        gres_match = re.search(r'#SBATCH\s+--gres=gpu:(\S+)?:(\d+)', content)
        node_count = re.search(r'#SBATCH\s+--nodes=(\d+)', content)
        tasks_per_node = re.search(r'#SBATCH\s+--ntasks-per-node=(\d+)', content)

        job_name = job_name.group(1) if job_name else "Unknown"
        cpus_per_task = int(cpus_per_task.group(1)) if cpus_per_task else 1
        gpus_per_task = int(gpus_per_task.group(1)) if gpus_per_task else 0
        gpu_type = gres_match.group(1) if gres_match and gres_match.group(1) else "None"
        node_count = int(node_count.group(1))
        tasks_per_node = int(tasks_per_node.group(1)) if tasks_per_node else 1

        total_tasks = node_count * tasks_per_node
        total_cpus = total_tasks * cpus_per_task

        if gres_match:
            total_gpus = int(gres_match.group(2)) * node_count  # Total GPUs based on gres directive
        else:
            total_gpus = gpus_per_task * total_tasks  # Total GPUs based on gpus-per-task directive if gres is not specified


        slurm_config = SlurmJobConfig(job_name, node_count, total_cpus, total_gpus, gpu_type, total_tasks)
        return slurm_config