#!bin/bash


LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.arrud.online

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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y
VALIDATE $? "Installing nginx:1.24"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removed Defult code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "Downloading and extracting frontend code"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Removed default conf"

cp nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied roboshop nginx conf"

systemctl restart nginx
Systemctl enable nginx
VALIDATE $? "enabled and restarted nginx"
