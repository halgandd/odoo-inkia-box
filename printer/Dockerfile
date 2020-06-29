FROM python:3.7-buster

RUN apt-get update && apt-get -y install \
whois \
wget \
lynx \
cups-filters \
foomatic-db-compressed-ppds \
printer-driver-all \
openprinting-ppds \
build-essential \
libssl-dev libffi-dev \
libxml2-dev \
libxslt1-dev \
zlib1g-dev \
libcups2-dev \
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

COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

COPY app.py .

EXPOSE 631
EXPOSE 5672

CMD ["/app.py" ]

