import sdk_cmd
import sdk_networks


def docker_exec(task, cmd):
    host_ip = sdk_networks.get_task_host(task)
    task_id = _get_task_container_id(task)

    exec_command = "sudo docker exec mesos-{} {}".format(task_id, cmd)
    return sdk_cmd.agent_ssh(host_ip, exec_command)


def docker_inspect(task, format_options=None):
    host_ip = sdk_networks.get_task_host(task)
    task_id = _get_task_container_id(task)

    inspect_cmd = "sudo docker inspect "

    if format_options is not None:
        inspect_cmd = inspect_cmd + format_options + " "

    inspect_cmd = inspect_cmd + "mesos-" + task_id
    return sdk_cmd.agent_ssh(host_ip, inspect_cmd)


def _get_task_container_id(task):
    for status in task['statuses']:
        if status['state'] == "TASK_RUNNING":
            return status['container_status']['container_id']['value']

    return None
