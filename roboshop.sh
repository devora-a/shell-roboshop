#!bin/bash

AMI_ID=ami-0220d79f3f480ecf5
ZONE_ID=Z04138223ALQPP4SRQZFJ
DOMAIN_NAME=arrud.online

for instance in $@
do
     echo "Launching instance: $instance"
     INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0220d79f3f480ecf5 \
        --instance-type t3.micro \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{key=Name,value=roboshop-$instance}]" \
        --query 'Instances[0].Instaanceid' \
        --output text
    )
    echo "Instance ID: $INSTANCE_ID"

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

    #### Updating R53 Record ####
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
            {   
                "comment": "Updating A record to new IP",
                "changes": [
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

