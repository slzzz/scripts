#!/bin/bash
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber
# if [ "$#" -ne 3 ]; then
#     echo "You must enter exactly 3 command line arguments"
# fi

function getInfo(){
    echo ==========================================
    lsblk
    df -h
    id
}

sudo curl https://s3.cn-northwest-1.amazonaws.com.cn/modelo.static.files/minio --output  /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
getInfo
read -p "Enter Path: " Path
read -p "Enter User: " User
if ! [ -d ${Path} ];then sudo mkdir -pv ${Path};sudo chown -R ${User}: ${Path};fi

MINIO_SECRET_KEY=`head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 20`

sudo tee /etc/default/minio >/dev/null <<EOF 
# Volume to be used for MinIO server.
MINIO_VOLUMES="${Path}"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ACCESS_KEY=Modelo
# Secret key of the server.
MINIO_SECRET_KEY=${MINIO_SECRET_KEY}
EOF

sudo tee /etc/systemd/system/minio.service >/dev/null   <<EOF 
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local/

User=${User}
Group=${User}

EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable minio.service
sudo systemctl start minio.service

echo "Minio passwd is ${MINIO_SECRET_KEY}"
