#!bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

SCRIPT_DIR=$PWD

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%y-%m-%d %H:%M:%S")

if [ $USER_ID -ne 0 ]; then
  echo -e "$TIMESTAMP [ERROR] $R please run this script with root access $N" | tee -a $LOGS_FILE
  exit 1
  fi
VALIDATE() {
if [ $1 -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
    exit 1
else
    echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
fi

}

dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y &>>$LOGS_FILE
dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs:20"


id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating roboshop user"
else
    echo -e "system user roboshop already created ... $Y skipping $N"
fi

rm -rf /app &>>$LOGS_FILE
VALIDATE $? "Removing existing code"

rm -rf /tmp/catalogue.zip 
VALIDATE $? "Removing catalogue zip"

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Downloading and extracting catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing catalogue dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding MongoDB repo"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB client"

INDEX=$(mongosh --host mongodb.arrud.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0]; then
    mongosh --host mongodb.arrud.online < /app/db/mater-data.js &>>$LOGS_FILE
VALIDATE $? "Loading products"
else
    echo -e "products already loaded ... $Y skipping $N"
fi

systemctl enable catalogue &>>$LOGS_FILE
systemctl restart catalogue &>>$LOGS_FILE 
VALIDATE $? "reStarting and enabling catalogue service"


