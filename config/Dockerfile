FROM python:3.8.3-slim-buster

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
usbutils \
cups-client

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY app /app
WORKDIR /app

EXPOSE 5000

ENTRYPOINT ["python3"]
CMD ["run.py"]