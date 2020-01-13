# -*- encoding: utf-8 -*-
"""
Python Application Template
Licence: GPLv3
"""

from flask import render_template, make_response, request
from app import app
import cups
import os
import re
import subprocess
from datetime import date
import nmap


@app.route('/configuration')
def configuration():
    return render_template('configuration.html', app=app)


@app.route('/form/env_file', methods=['GET', 'POST'])
def contact():
    data = request.form
    print(data)
    path = os.environ.get('PATH_ENV_FILE') + "/file.env"
    f = open(path, "w+")
    if data.get('raspberry_name'):
        f.write("RASPBERRY_NAME=%s\r\n" %(data.get('raspberry_name', 'raspberry_name')))
    if data.get('cups_password'):
        f.write("CUPS_PASSWORD=%s\r\n" %(data.get('cups_password', 'password')))
    if data.get('cups_login'):
        f.write("CUPS_LOGIN=%s\r\n" %(data.get('cups_login', 'root')))
    f.close()
    return render_template('private/confirmation_create_file.html', app=app)




@app.route('/')
def index():
    def get_cups_printer():
        try:
            conn = cups.Connection()
            return conn.getPrinters()
        except:
            # logger.info("printer problem")
            return {}

    def get_network_devices():
        return False
        nm = nmap.PortScanner()
        nm.scan(hosts='192.168.1.0/24', arguments='-n -sP -PE -PA21,23,80,3389')
        return [(x, nm[x]['status']['state']) for x in nm.all_hosts()]

    def get_usb_devices():
        device_re = re.compile("Bus\s+(?P<bus>\d+)\s+Device\s+(?P<device>\d+).+ID\s(?P<id>\w+:\w+)\s(?P<tag>.+)$", re.I)
        df = subprocess.check_output("lsusb")
        devices = []
        for i in df.decode('utf-8').split('\n'):
            if i:
                info = device_re.match(i)
                if info:
                    dinfo = info.groupdict()
                    dinfo['device'] = '/dev/bus/usb/%s/%s' % (dinfo.pop('bus'), dinfo.pop('device'))
                    devices.append(dinfo)
        return devices

    def get_host_mac_address():
        return os.environ.get("MAC_ADDRESS")

    def get_raspberry_name():
        return os.environ.get("RASPBERRY_NAME")

    return render_template("index.html", app=app,
                           cups_printer = get_cups_printer(),
                           network_devices = get_network_devices(),
                           usb_devices = get_usb_devices(),
                           host_mac_address = get_host_mac_address(),
                           raspberry_name = get_raspberry_name())
