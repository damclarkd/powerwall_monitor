# Powerwall_Monitor
Monitoring the Tesla Powerwall with the TICK framework

![Imgur](https://i.imgur.com/TuwFYTs.png)

## Requirements
* docker
* docker-compose

## Installation

### Docker Containers

* Edit `powerwall.yml` and look for the section under `pypowerall` and update the following details for your Powerwall:
```yml
            PW_PASSWORD: "password"
            PW_EMAIL: "email@example.com"
            PW_HOST: "192.168.91.1"
            PW_TIMEZONE: "Australia/Adelaide"
```

* Start the docker containers: `docker-compose -f powerwall.yml up -d`

### InfluxDB

* Connect to the Influx database shell: `docker exec -it influxdb influx`
* At the database prompt, you will need to enter (copy/paste) the following commands after you adjust the timezone (tz) as appropriate:
	```sql
	USE powerwall
	CREATE RETENTION POLICY raw ON powerwall duration 3d replication 1
	ALTER RETENTION POLICY autogen ON powerwall duration 365d
	CREATE RETENTION POLICY kwh ON powerwall duration INF replication 1
	CREATE RETENTION POLICY daily ON powerwall duration INF replication 1
	CREATE RETENTION POLICY monthly ON powerwall duration INF replication 1
	CREATE CONTINUOUS QUERY cq_autogen ON powerwall BEGIN SELECT mean(home) AS home, mean(solar) AS solar, mean(from_pw) AS from_pw, mean(to_pw) AS to_pw, mean(from_grid) AS from_grid, mean(to_grid) AS to_grid, last(percentage) AS percentage INTO powerwall.autogen.:MEASUREMENT FROM (SELECT load_instant_power AS home, solar_instant_power AS solar, abs((1+battery_instant_power/abs(battery_instant_power))*battery_instant_power/2) AS from_pw, abs((1-battery_instant_power/abs(battery_instant_power))*battery_instant_power/2) AS to_pw, abs((1+site_instant_power/abs(site_instant_power))*site_instant_power/2) AS from_grid, abs((1-site_instant_power/abs(site_instant_power))*site_instant_power/2) AS to_grid, percentage FROM raw.http) GROUP BY time(1m), month, year fill(linear) END
	CREATE CONTINUOUS QUERY cq_kwh ON powerwall RESAMPLE EVERY 1m BEGIN SELECT integral(home)/1000/3600 AS home, integral(solar)/1000/3600 AS solar, integral(from_pw)/1000/3600 AS from_pw, integral(to_pw)/1000/3600 AS to_pw, integral(from_grid)/1000/3600 AS from_grid, integral(to_grid)/1000/3600 AS to_grid INTO powerwall.kwh.:MEASUREMENT FROM autogen.http GROUP BY time(1h), month, year tz('Australia/Adelaide') END
	CREATE CONTINUOUS QUERY cq_daily ON powerwall RESAMPLE EVERY 1h BEGIN SELECT sum(home) AS home, sum(solar) AS solar, sum(from_pw) AS from_pw, sum(to_pw) AS to_pw, sum(from_grid) AS from_grid, sum(to_grid) AS to_grid INTO powerwall.daily.:MEASUREMENT FROM powerwall.kwh.http GROUP BY time(1d), month, year tz('Australia/Adelaide') END 
	CREATE CONTINUOUS QUERY cq_monthly ON powerwall RESAMPLE EVERY 1h BEGIN SELECT sum(home) AS home, sum(solar) AS solar, sum(from_pw) AS from_pw, sum(to_pw) AS to_pw, sum(from_grid) AS from_grid, sum(to_grid) AS to_grid INTO powerwall.monthly.:MEASUREMENT FROM powerwall.daily.http GROUP BY time(365d), month, year END
	```

Note: the database queries are set to use `Australia/Adelaide` as timezone. Edit the database commands above to replace `Australia/Adelaide` with your own timezone.

### Grafana Setup

* Open up Grafana in a browser at `http://<server ip>:9000` and login with `admin/admin`
* From `Configuration\Data Sources`, add `InfluxDB` database with:
  - name: `InfluxDB`
  - url: `http://influxdb:8086`
  - database: `powerwall`
  - min time interval: `5s`
* From `Configuration\Data Sources`, add `Sun and Moon` database with:
  - name: `Sun and Moon`
  - your latitude and longitude
* Edit `dashboard.json` to replace `Australia/Adelaide` with your own timezone.
* From `Dashboard\Manage`, select `Import`, and upload `dashboard.json`

### Notes

* The database queries and dashboard are set to use `Australia/Adelaide` as the timezone. Remember to edit the database commands and the `dashboard.json` file to replace `Australia/Adelaide` with your own timezone.

* InfluxDB does not run reliably on older models of Raspberry Pi, resulting in the Docker container terminating with `error 139`.  

Enjoy!

---
If you found this useful, say _Thank You!_ [with a beer.](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mihailescu2m%40gmail%2Ecom&lc=AU&item_name=memeka&item_number=odroid&currency_code=AUD&bn=PP%2DDonationsBF%3Abtn_donate_LG%2Egif%3ANonHosted)

