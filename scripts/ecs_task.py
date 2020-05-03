import os
import logging
import json
import urllib.request
from uuid import uuid4

import boto3

# Configure logging
logging.basicConfig()
log = logging.getLogger()
log.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))
jsonify = lambda data: json.dumps(data, default=str)

# Boto 3 client
client = boto3.client('ecs')


def handler(event, context):
    """Lambda handler"""
    message = 'Task completed successfully'
    result = 'SUCCESS'
    try:
        log.info(f'Received event: {jsonify(event)}')
        if event['RequestType'] in ['Create', 'Update']:
            # Run task
            tasks = client.run_task(
                cluster=event['ResourceProperties']['Cluster'],
                taskDefinition=event['ResourceProperties']['TaskDefinition'],
                overrides=event['ResourceProperties'].get('Overrides',{}),
                count=1,
                startedBy=event['RequestId'],
                launchType='FARGATE',
                networkConfiguration={
                    'awsvpcConfiguration': {
                        'subnets': event['ResourceProperties']['Subnets'],
                        'securityGroups': event['ResourceProperties']['SecurityGroups'],
                        'assignPublicIp': 'ENABLED'
                    }
                }
            )
            task = event['PhysicalResourceId'] = tasks['tasks'][0]['taskArn']
            log.info(f'Started task {task}')
            # Wait for task to complete
            waiter = client.get_waiter('tasks_stopped')
            waiter.wait(
                cluster=event['ResourceProperties']['Cluster'],
                tasks=[task],
            )
            response = client.describe_tasks(
                cluster=event['ResourceProperties']['Cluster'],
                tasks=[task]
            )
            log.info(f'Task response: {jsonify(response)}')
            # Check container exit code
            container = response['tasks'][0]['containers'][0]
            exit_code = container.get('exitCode', 255)
            if exit_code != 0:
                message = f'Task failed with exit code {exit_code}'
                result = 'FAILED'
                log.error(message)
        else:
            message = 'Skipping delete request'
            log.info('Skipping delete request')
    except Exception as e:
        message = 'An error occurred'
        log.exception('An error occurred')
        result = 'FAILED'
    finally:
        event['Status'] = result
        event['Reason'] = message
        callback(event)


def callback(event):
    """Sends response to CloudFormation"""
    headers = {'content-type': ''}
    url = event['ResponseURL']
    data = json.dumps({
        'Status': event['Status'],
        'Reason': event['Reason'],
        'PhysicalResourceId': event.get('PhysicalResourceId', str(uuid4())),
        'StackId': event['StackId'],
        'RequestId': event['RequestId'],
        'LogicalResourceId': event['LogicalResourceId'],
        'Data': event.get('Data', {})
    }).encode()
    log.info(f'Submitting response to {url}: {jsonify(data)}')
    request = urllib.request.Request(url, data=data, headers=headers, method='PUT')
    response = urllib.request.urlopen(request)
    body = response.read()
    log.info(f'Response from CloudFormation: {response.status} {body}')
