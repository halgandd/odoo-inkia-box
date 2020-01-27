FROM debian:buster

RUN apt-get update && apt-get -y install \
python3.5 \
whois \
wget \
lynx \
cups-filters \
foomatic-db-compressed-ppds \
printer-driver-all \
openprinting-ppds \
python3-pip \
build-essential \
libssl-dev libffi-dev \
libxml2-dev \
libxslt1-dev \
zlib1g-dev \
libcups2-dev \
python3.7-dev \
locales \
sudo \
whois \
cups \
foomatic-db-compressed-ppds \
openprinting-ppds \
gutenprint-locales \
python-nmap \
cups-client \
vim

#COPY ./print_rabbitmq_module/print_rabbitmq.py /opt/script_print_rabbitmq/

COPY ./print_rabbitmq_module/requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

COPY ./print_rabbitmq_module/broker_rabbit /tmp/broker_rabbit
RUN pip3 install /tmp/broker_rabbit

WORKDIR /opt/script_print_rabbitmq/
COPY ./print_rabbitmq_module/print_rabbitmq.py /opt/script_print_rabbitmq/
CMD [ "/opt/script_print_rabbitmq/print_rabbitmq.py" ]




#
#COPY ./print_rabbitmq.sh /etc/init.d/print_rabbitmq
#RUN chmod 755 /etc/init.d/print_rabbitmq
#RUN update-rc.d print_rabbitmq defaults