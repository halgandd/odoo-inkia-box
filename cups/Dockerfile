FROM lemariva/rpi-cups
COPY ./CUPS-driver_v1.2-56.tgz /tmp/

RUN apt-get update 
RUN apt-get install -y gcc automake autoconf ghostscript poppler-utils netpbm build-essential
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && locale-gen en_US.UTF-8
RUN cd /tmp && tar xvf CUPS-driver_v1.2-56.tgz
RUN cd /tmp/cupsdriver-1.2-56/ && autoreconf --install --force && ./configure &&  make -s &&  make install
COPY ./config/cupsd.conf /etc/cups/cupsd.conf