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

dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing python"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating roboshop user"
else
    echo -e "system user roboshop already created ... $Y skipping $N"
fi

rm -rf /app &>>$LOGS_FILE
VALIDATE $? "Removing existing code"

rm -rf /tmp/payment.zip 
VALIDATE $? "Removing payment zip"

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
cd /app 
unzip /tmp/payment.zip
VALIDATE $? "Downloading and extracting payment code"

pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing pip3"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Created systemctl service"

 

systemctl enable payment &>>$LOGS_FILE
systemctl restart payment &>>$LOGS_FILE
VALIDATE $? "enable and restarted payment" 

