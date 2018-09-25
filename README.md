
# nagios-influxdb-grafana
- Building Docker image for Nagios core 4.4.2 on centos:latest
- Also running InfluxDB and Grafana for performance graph
- Grafana integrated into Nagios Core Interface  

# BuildInstruction 
  Update Dockerfile with Nagios core Container or Host IP, or pass IP Address as value to build parameter 'HOST_IP'.

    #docker build <Dockerfile Path> -t <repo>/nagios-influxdb-grafana:u04
  
# RunInstruction
  Start container:
  
    #docker run --name nagiosfluxdbgrafana -itd --network host \
    -v "nagios-var:/usr/local/nagios/var" -v "nagios-etc:/usr/local/nagios/etc"\
    -v "influxdb-data:/var/lib/influxdb" -v "grafana:/var/lib/grafana" \
    <repo>/nagios-influxdb-grafana:u04
 
# To Build container with persistent storage below volume mappings required:
 
 - nagios-var:/usr/local/nagios/var
 - nagios-etc:/usr/local/nagios/etc
 - influxdb-data:/var/lib/influxdb
 - grafana:/var/lib/grafana
 
# Access URLs

- Nagios : http://\<IP Address\>/nagios/   - Default user : nagiosadmin   Password: nagiosadmin
- Grafana : http://\<IP Address\>:3000     - Default user : admin password: admin

![Alt text](nagios-screenshot.PNG?raw=true "Nagios")
![Alt text](grafana-screenshot.PNG  width=100)

  
# Reference
https://support.nagios.com/kb/article/nagios-core-performance-graphs-using-influxdb-nagflux-grafana-histou-802.html
http://docs.grafana.org/installation/docker/
https://docs.influxdata.com/influxdb/v1.6/introduction/installation/
