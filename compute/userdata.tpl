#!/bin/bash
yum update -y
yum install git -y
git clone https://github.com/pradeeppanga/aws-exercise.git
cd /aws-exercise
virtualenv panga
source panga/bin/activate
make init
python aws_webservice/aws_webservice.py 1> /var/log/aws_webservice.log 2>&1 &
cat << EOF > /root/aws-webservice.sh 
#!/bin/bash
cd /aws-exercise
source panga/bin/activate
python aws_webservice/aws_webservice.py 1> /var/log/aws_webservice.log 2>&1 &
EOF
chmod 700 /root/aws-webservice.sh
echo "@reboot bash /root/aws-webservice.sh" >> /var/spool/cron/root

