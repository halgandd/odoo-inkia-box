FROM python:3.7-slim-buster

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

COPY app.py .

ENTRYPOINT ["python3"]
CMD ["/app.py" ]

