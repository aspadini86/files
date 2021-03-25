## Amazon Elastic Container (ECS)
## Cocmandos ECS para interagir via command line

## Listando os cluster ativos 
aws ecs list-clusters
{
    "clusterArns": [
        "arn:aws:ecs:us-east-1:116667764712:cluster/default"
    ]
}

## Listando os serviços do ECS
 aws ecs list-services
{
    "serviceArns": [
        "arn:aws:ecs:us-east-1:116667764712:service/default/sample-app-service"
    ]
}

## Listando serviços de um determinado cluster 
aws ecs list-services --cluster default
{
    "serviceArns": [
        "arn:aws:ecs:us-east-1:116667764712:service/default/sample-app-service"
    ]
}