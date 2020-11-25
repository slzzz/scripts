#!/bin/bash

function default(){
  sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install postgresql-9.6
}

default
sudo systemctl enable postgresql
sudo systemctl start postgresql


# create user and grant permission
# CREATE USER user WITH PASSWORD 'xxxx';
# GRANT ALL PRIVILEGES ON DATABASE dbname TO user;
# default config /etc/postgresql/9.6/main/pg_hba.conf
# host    all             all             172.0.0.1/24                md5

