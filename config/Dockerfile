FROM python:3.7-buster

RUN apt-get update && apt-get -y install \
whois \
wget \
lynx \
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




EXPOSE 8091
EXPOSE 8090

ENTRYPOINT ["python3"]
CMD ["run.py"]