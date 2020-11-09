#!/bin/bash
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

if [ "$#" -ne 3 ]; then
    echo "You must enter exactly 3 command line arguments"
fi

function getInfo(){
    echo ==========================================
    lsblk
    df -h
    id
}

curl https://dl.min.io/server/minio/release/linux-amd64/minio --output  /usr/local/bin/minio
getInfo
read -p "Enter Path: " Path
read -p "Enter User: " User
if ! [ -d ${Path} ];then mkdir -pv ${Path};fi

MINIO_SECRET_KEY=`head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 20`

cat <<EOT >> /etc/default/minio
# Volume to be used for MinIO server.
MINIO_VOLUMES="${Path}"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ACCESS_KEY=Modelo
# Secret key of the server.
MINIO_SECRET_KEY=${MINIO_SECRET_KEY}
EOT

cat <EOT >> /etc/systemd/system/minio.service
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

ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target

# Built for ${project.name}-${project.version} (${project.name})

systemctl enable minio.service
systemctl start minio.service
