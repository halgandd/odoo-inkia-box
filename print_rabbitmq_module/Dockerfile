FROM debian:buster

RUN apt-get update && apt-get -y install \
python3.5 \
whois \
wget \
python3-pip \
build-essential \
libssl-dev libffi-dev \
libxml2-dev \
libxslt1-dev \
zlib1g-dev \
libcups2-dev \
python3.7-dev

COPY ./broker_rabbit /tmp/broker_rabbit
RUN pip3 install /tmp/broker_rabbit

COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

COPY ./print_rabbitmq.sh /etc/init.d/print_rabbitmq
RUN chmod 755 /etc/init.d/print_rabbitmq
RUN update-rc.d print_rabbitmq defaults

