#!/bin/bash
#
# Interactive Setup Script for powerwall_monitor
# by Jason Cox - 21 Jan 2022

# Build Deploy Directory
mkdir -p deploy
cd deploy
mkdir -p grafana
mkdir -p influxdb
echo "Copy latest files into deploy folder..."
cp ../* . &> /dev/null
echo "-----------------------------------------"

# Replace Credentials 
echo "Enter credentials for Powerwall..."
read -p 'Password: ' PASSWORD
read -p 'Email: ' EMAIL
read -p 'IP Address: ' IP
read -p 'Timezone (default America/Los_Angeles): ' TZ

echo ""
echo "Updating..."
sed -i .bak "s/password/${PASSWORD}/g" powerwall.yml
sed -i .bak "s/email@example.com/${EMAIL}/g" powerwall.yml
sed -i .bak "s/192.168.91.1/${IP}/g" powerwall.yml
if [ -z "${TZ}" ]; then ./tz.sh "${TZ}"; fi
echo "-----------------------------------------"

# Clean up old containers
echo "Cleaning up old containers..."
docker-compose -f powerwall.yml down
docker-compose -f powerwall.yml rm
docker rm pypowerwall
docker images | grep pypowerwall | awk '{print $3}' | xargs docker rmi -f
docker rm telegraf
docker images | grep telegraf | awk '{print $3}' | xargs docker rmi -f
docker rm grafana
docker images | grep grafana | awk '{print $3}' | xargs docker rmi -f
docker rm influxdb
docker images | grep influxdb | awk '{print $3}' | xargs docker rmi -f
# The following will destory any previous data or setup
#rm -rf grafana
#rm -rf influxdb
#mkdir grafana
#mkdir influxdb
echo "-----------------------------------------"

# Build Docker
echo "Build New Docker-Compose..."
docker-compose -f powerwall.yml up -d
echo "-----------------------------------------"

# Set up Influx
echo "Setting up InfluxDB..."
echo "Waiting to start..."
sleep 5
#pbcopy < influxdb.sql
echo "------------influxdb.sql-----------------"
cat influxdb.sql
echo ""
echo "^-----------influxdb.sql----------------^"
echo "Copy and Paste influxdb.sql and ^D to end..."
docker exec -it influxdb influx
echo "Opening Grafana... use admin/admin for login..."
sleep 12
open "http://localhost:9000/"

cat << EOF
Follow these instructions:

* From 'Configuration\Data Sources' add 'InfluxDB' database with:
  - Name: 'InfluxDB'
  - URL: 'http://influxdb:8086'
  - Database: 'powerwall'
  - Min time interval: '5s'
  - Click "Save & test" button

* From 'Configuration\Data Sources' add 'Sun and Moon' database with:
  - Name: 'Sun and Moon'
  - Enter your latitude and longitude (some browsers will use your location)
  - Click "Save & test" button

* From 'Dashboard\Manage' (or 'Dashboard\Browse'), select 'Import', and upload 'dashboard.json' from the deploy folder.
EOF
