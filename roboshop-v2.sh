#!bin/bash


AMI_ID=ami-0220d79f3f480ecf5
ZONE_ID=Z04138223ALQPP4SRQZFJ
DOMAIN_NAME=arrud.online
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

### validation ###
if [ $# -lt 2 ]; then
  echo -e "$R ERROR: : Atleast 2 arguments required $N"
  echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
  exit 1
fi

ACTION=$1
shift # first argument will be removed

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
    echo -e "$R ERROR: : First argument must be either 'create' or 'delete' $N"
    echo "UASGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

get_instance_id(){
    name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text

}    

for instance in $@
do  
    INSTANCE_ID=$(get_instance_id $instance)
    if [ $ACTION == "create" ]; then
        if [ $INSTANCE_ID == "None" ]; then ...
        else    
            echo "roboshop-$instance already running: $INSTANCE_ID"
        fi

        # update R53 record
        if [ $instance == "frountend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
         --query 'Reservations[*].Instances[*].PublicIpAddress' \
         --output text
        )
        R53_RECORD="$DOMAIN_NAME"
        else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
         --query 'Reservations[*].Instances[*].PrivateIpAddress' \
         --output text
        )
        R53_RECORD="$instance.$DOMAIN_NAME"
    fi


     
    fi
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
       {   
            "Comment": "Updating A record to new IP",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": "'$R53_RECORD'",
                        "Type": "A",
                        "TTL": 1,
                        "ResourceRecords": [
                            {
                                "Value": "'$IP'"
                    }   ]   }
                }
            ]
                
        }
    '
done
