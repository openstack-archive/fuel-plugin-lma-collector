FROM nginx:latest

ADD https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz /tmp/kibana.tar.gz
ADD http://grafanarel.s3.amazonaws.com/grafana-1.9.1.tar.gz /tmp/grafana.tar.gz
ADD run.sh /usr/local/bin/run

RUN tar zxf /tmp/kibana.tar.gz && mv kibana-3.1.2 /usr/share/nginx/html/kibana && rm -rf /tmp/kibana*
RUN tar zxvf /tmp/grafana.tar.gz && mv grafana-1.9.1 /usr/share/nginx/html/grafana && rm -rf /tmp/grafana*

EXPOSE 80

CMD ["/usr/local/bin/run"]
