#!/bin/bash
#$1 MINIO_VOLUMES
#$2 MINIO_SECRET_KEY
#$3 USER
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

if [ "$#" -ne 3 ]; then
    echo "You must enter exactly 3 command line arguments"
fi

echo $#

curl https://dl.min.io/server/minio/release/linux-amd64/minio --output  /usr/local/bin/minio

cat <<EOT >> /etc/default/minio
# Volume to be used for MinIO server.
MINIO_VOLUMES="$1"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ACCESS_KEY=Modelo
# Secret key of the server.
MINIO_SECRET_KEY=$2
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

User=$3
Group=$3

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
