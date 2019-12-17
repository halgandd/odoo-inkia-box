FROM debian:buster

RUN apt-get update && apt-get -y install \
python3.5 \
whois \
wget \
lynx \
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
printer-driver-all \
foomatic-db-compressed-ppds \
openprinting-ppds \
gutenprint-locales \
usbutils \
nmap

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY app /app
WORKDIR /app

ENTRYPOINT ["python3"]
CMD ["run.py"]