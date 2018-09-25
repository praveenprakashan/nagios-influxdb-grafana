##########################################################################
#    Dockerfile to create Nagioscore 4.4.2 + Influxdb + Grafana image    #
##########################################################################
FROM centos:latest

LABEL Version=1.4
LABEL Description="Dockerfile to create Nagioscore 4.4.2 image"
LABEL Maintainer="Praveen Prakashan"
LABEL LastModified="25-10-2018"
LABEL BuildInstruction="docker build <Dockerfile Path> -t <repo>/nagios-influxdb-grafana:u04"
LABEL RunInstruction='docker run --name nagiosfluxdb -itd --network host -v "nagios-var:/usr/local/nagios/var" -v "nagios-etc:/usr/local/nagios/etc" -v "influxdb-data:/var/lib/influxdb" -v "grafana:/var/lib/grafana" <repo>/nagios-influxdb-grafana:u04'

#Install pre-requisite
RUN yum install -y gcc glibc glibc-common wget unzip httpd php gd gd-devel perl postfix make gettext automake autoconf openssl-devel net-snmp net-snmp-utils epel-release which openssl
RUN yum install -y perl-Net-SNMP
RUN yum install -y golang golang-github-influxdb-influxdb-client golang-github-influxdb-influxdb-datastore git
ADD golang-github-influxdb-influxdb-client-0.9.5.1-0.8.git9eab563.fc29.noarch.rpm /tmp/golang-github-influxdb-influxdb-client-0.9.5.1-0.8.git9eab563.fc29.noarch.rpm
RUN rpm -i /tmp/golang-github-influxdb-influxdb-client-0.9.5.1-0.8.git9eab563.fc29.noarch.rpm


#Install Nagios Core
WORKDIR /tmp
RUN wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.2.tar.gz
RUN tar xzf nagioscore.tar.gz
WORKDIR /tmp/nagioscore-nagios-4.4.2/
RUN ./configure
RUN make all
RUN make install-groups-users
RUN usermod -a -G nagios apache
RUN make install
RUN make install-daemoninit
RUN make install-commandmode
RUN make install-config
RUN make install-webconf
ADD nagios.cfg /usr/local/nagios/etc/
ADD commands.cfg /usr/local/nagios/etc/objects/

#Install Nagios plugin
WORKDIR /tmp
RUN wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
RUN tar zxf nagios-plugins.tar.gz
WORKDIR /tmp/nagios-plugins-release-2.2.1/
RUN ./tools/setup
RUN ./configure
RUN make
RUN make install

#Install NRPE
WORKDIR /tmp
RUN wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz
RUN tar -xf nrpe-3.2.1.tar.gz
WORKDIR nrpe-3.2.1
RUN ./configure
RUN make check_nrpe
RUN make install-plugin
WORKDIR /root

#Set Login password for nagiosadmin user
RUN htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

#Install Nagflux
ENV GOPATH /tmp/gorepo
ENV NAGFLUX_CONFIG /opt/nagflux/config.gcfg
RUN mkdir ${GOPATH}
RUN go get -v -u github.com/griesbacher/nagflux
RUN go build github.com/griesbacher/nagflux
RUN mkdir -p /opt/nagflux
RUN cp ${GOPATH}/bin/nagflux /opt/nagflux/
RUN mkdir -p /usr/local/nagios/var/spool/nagfluxperfdata
RUN chown nagios:nagios /usr/local/nagios/var/spool/nagfluxperfdata
ADD config.gcfg ${NAGFLUX_CONFIG}
ADD nagflux /etc/init.d/nagflux
RUN chmod +x /etc/init.d/nagflux

#Install Influxdb
ADD influxdb.repo /etc/yum.repos.d/
RUN yum -y install influxdb
ADD influxdb-init.sh /etc/init.d/
RUN chmod +x /etc/init.d/influxdb-init.sh

#Install Grafana
ADD grafana.repo /etc/yum.repos.d/
RUN yum -y install grafana
ADD grafana-datastore.yml /etc/grafana/provisioning/datasources/nagflux.yaml
RUN chown root:grafana /etc/grafana/provisioning/datasources/nagflux.yaml

#Install histou
ARG HOST_IP='192.168.134.77'
WORKDIR /tmp
RUN wget -O histou.tar.gz https://github.com/Griesbacher/histou/archive/v0.4.3.tar.gz
RUN mkdir -p /var/www/html/histou
WORKDIR /var/www/html/histou
RUN tar xzf /tmp/histou.tar.gz --strip-components 1
RUN cp histou.ini.example histou.ini
RUN cp histou.js /usr/share/grafana/public/dashboards/
RUN sed -i "s/localhost/$HOST_IP/g" /usr/share/grafana/public/dashboards/histou.js
ADD templates.cfg /usr/local/nagios/etc/objects/templates.cfg
RUN sed -i "s/GRAFANASERVER/$HOST_IP/g" /usr/local/nagios/etc/objects/templates.cfg
WORKDIR /root

RUN echo "/etc/init.d/nagios start;/etc/init.d/influxdb-init.sh start;/etc/init.d/nagflux start;/etc/init.d/grafana-server start;/usr/sbin/httpd -D FOREGROUND" > /bin/run.sh
CMD ["/bin/bash","/bin/run.sh"]

EXPOSE 80
EXPOSE 8088
EXPOSE 8086
EXPOSE 3000

