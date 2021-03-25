## Amazon Elastic Container (ECS)
## Cocmandos ECS para interagir via command line

##
## Listando os cluster ativos 
aws ecs list-clusters
{
    "clusterArns": [
        "arn:aws:ecs:us-east-1:116667764712:cluster/default"
    ]
}

##
## Listando os serviços do ECS
 aws ecs list-services
{
    "serviceArns": [
        "arn:aws:ecs:us-east-1:116667764712:service/default/sample-app-service"
    ]
}

##
## Listando serviços de um determinado cluster 
aws ecs list-services --cluster default
{
    "serviceArns": [
        "arn:aws:ecs:us-east-1:116667764712:service/default/sample-app-service"
    ]
}


##
## Listando tarefas em execução 
aws ecs list-tasks
{
    "taskArns": []
}

## Modificando a qtd de tarefas em linha de comando
## Nesse exemploe estou alterando para 2 tarefas 
aws ecs update-service --service sample-app-service --desired-count 2
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-east-1:116667764712:service/default/sample-app-service",
        "serviceName": "sample-app-service",
        "clusterArn": "arn:aws:ecs:us-east-1:116667764712:cluster/default",
        "loadBalancers": [],
        "serviceRegistries": [],
        "status": "ACTIVE",
        "desiredCount": 2,
....

##
## Listando tarefas em execução 
aws ecs list-tasks
{
    "taskArns": [
        "arn:aws:ecs:us-east-1:116667764712:task/default/90102bc6ff0d4ca4a34b1392cb0163ef",
        "arn:aws:ecs:us-east-1:116667764712:task/default/fe67b4a47879483d98bd6ced077af162"
    ]
}


#
## Exibindo informações do cluster 
aws ecs describe-clusters
{
    "clusters": [
        {
            "clusterArn": "arn:aws:ecs:us-east-1:116667764712:cluster/default",
            "clusterName": "default",
            "status": "ACTIVE",
            "registeredContainerInstancesCount": 0,
            "runningTasksCount": 2,
            "pendingTasksCount": 0,
            "activeServicesCount": 1,
            "statistics": [],
            "tags": [],
            "settings": [
                {
                    "name": "containerInsights",
                    "value": "disabled"
                }
            ],
            "capacityProviders": [],
            "defaultCapacityProviderStrategy": []
        }
    ],
    "failures": []
}


##
## Trabalhando com query 
## Listando todos os cluster 
## Exibindo o Nome e runningTaskCount
aws ecs describe-clusters --query 'clusters[*].[clusterName,runningTasksCount]'
[
    [
        "default",
        2
    ]
]


##
## Exibindo todas as informações das tasks 
aws ecs describe-tasks --cluster default --tasks 90102bc6ff0d4ca4a34b1392cb0163ef
{
    "tasks": [
        {
            "attachments": [
                {
                    "id": "8499f13f-75dd-45a7-89c5-b471869a3028",
                    "type": "ElasticNetworkInterface",
                    "status": "ATTACHED",
                    "details": [
                        {
                            "name": "subnetId",
                            "value": "subnet-0de0de16ad642d444"
                        },
                        {
                            "name": "networkInterfaceId",
                            "value": "eni-0ecd68609ec91adae"
                        },
                        {
                            "name": "macAddress",
                            "value": "0a:8b:34:b5:89:9b"
                        },
                        {
                            "name": "privateDnsName",
                            "value": "ip-10-0-1-148.ec2.internal"
                        },
                        {
                            "name": "privateIPv4Address",
                            "value": "10.0.1.148"
                        }
                    ]
                }
            ],
....


##
## Qtd de CPU e Memoria de uma determinada query 
aws ecs describe-tasks --cluster default --tasks 90102bc6ff0d4ca4a34b1392cb0163ef --query 'tasks[*].{cpu:cpu,memoria:memory}'
[
    {
        "cpu": "256",
        "memoria": "512"
    }
]


##
## autoscaling describe 
aws autoscaling describe-auto-scaling-groups
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupName": "EC2ContainerService-ecs-api-EcsInstanceAsg-1AQOLJI6J1S2E",
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-east-1:116667764712:autoScalingGroup:06e985ab-3696-4ae5-adb6-01b5b40b1c8b:autoScalingGroupName/EC2ContainerService-ecs-api-EcsInstanceAsg-1AQOLJI6J1S2E",
            "LaunchConfigurationName": "EC2ContainerService-ecs-api-EcsInstanceLc-OIBJMXZ08TW0",
            "MinSize": 0,
            "MaxSize": 4,
            "DesiredCapacity": 3,
            "DefaultCooldown": 300,
            "AvailabilityZones": [
                "us-east-1a",
                "us-east-1b"
            ],
...

##
## Alterando o autoscalling para 2 instâncias 
aws autoscaling set-desired-capacity --auto-scaling-group-name EC2ContainerService-ecs-api-EcsInstanceAsg-1AQOLJI6J1S2E --desired-capacity 2


