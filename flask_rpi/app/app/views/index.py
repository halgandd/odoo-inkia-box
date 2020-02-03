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
    def get_env(env_name):
        return os.environ.get(env_name, "")

    return render_template('configuration.html', app=app,
                           host_mac_address=get_env("MAC_ADDRESS"),
                           queue_names=get_env("QUEUE_NAMES"),
                           queue_configuration=get_env("QUEUE_CONFIGURATION"),
                           printer_name=get_env("PRINTER_NAME"),
                           cups_login=get_env("CUPS_LOGIN"),
                           cups_password=get_env("CUPS_PASSWORD"),
                           rabbitmq_user=get_env("RABBITMQ_USER"),
                           rabbitmq_password=get_env("RABBITMQ_PASSWORD"),
                           rabbitmq_host=get_env("RABBITMQ_HOST"),
                           rabbitmq_port=get_env("RABBITMQ_PORT"),
                           rabbitmq_path=get_env("RABBITMQ_PATH"),
                           rabbitmq_exchange=get_env("RABBITMQ_EXCHANGE_NAME"),
                           rabbitmq_delivery_mode=get_env("RABBITMQ_DELIVERY_MODE"),
                           rabbitmq_https=get_env("RABBITMQ_HTTPS"),
                           raspberry_name=get_env("RASPBERRY_NAME")
                           )


@app.route('/form/env_file', methods=['GET', 'POST'])
def contact():
    def set_env(file, data_form, env_name, var_name, default=""):
        if data_form.get(var_name):
            val = data.get(var_name, default)
            file.write("%s=%s\r\n" % (env_name, val))
            os.environ[env_name] = val

    data = request.form
    app.logger.info(str(data))
    path = os.environ.get('PATH_ENV_FILE') + "/file.env"
    f = open(path, "w+")

    set_env(f, data, "RASPBERRY_NAME", "raspberry_name")
    set_env(f, data, "CUPS_PASSWORD", "cups_password", "password")
    set_env(f, data, "CUPS_LOGIN", "cups_login", "root")
    set_env(f, data, "QUEUE_NAMES", "queue_names")
    set_env(f, data, "QUEUE_CONFIGURATION", "queue_configuration")
    set_env(f, data, "RABBITMQ_USER", "rabbitmq_user")
    set_env(f, data, "RABBITMQ_PASSWORD", "rabbitmq_password")
    set_env(f, data, "RABBITMQ_HOST", "rabbitmq_host")
    set_env(f, data, "RABBITMQ_PORT", "rabbitmq_port")
    set_env(f, data, "RABBITMQ_PATH", "rabbitmq_path", "2F")
    set_env(f, data, "RABBITMQ_EXCHANGE_NAME", "rabbitmq_exchange")
    set_env(f, data, "RABBITMQ_DELIVERY_MODE", "rabbitmq_delivery_mode")
    set_env(f, data, "RABBITMQ_HTTPS", "rabbitmq_https", "1")
    set_env(f, data, "PRINTER_NAME", "printer_name", "printer")

    f.write("%s=%s\r\n" % ("FILELOG", os.environ.get("FILELOG")))
    f.write("%s=%s\r\n" % ("LOG_LEVEL", os.environ.get("LOG_LEVEL")))


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

    def get_env(env_name):
        return os.environ.get(env_name)

    return render_template("index.html", app=app,
                           cups_printer=get_cups_printer(),
                           network_devices=get_network_devices(),
                           usb_devices=get_usb_devices(),
                           printer_name=get_env("PRINTER_NAME"),
                           cups_login=get_env("CUPS_LOGIN"),
                           cups_password=get_env("CUPS_PASSWORD"),
                           host_mac_address=get_env("MAC_ADDRESS"),
                           queue_names=get_env("QUEUE_NAMES"),
                           queue_configuration=get_env("QUEUE_CONFIGURATION"),
                           rabbitmq_user=get_env("RABBITMQ_USER"),
                           rabbitmq_password=get_env("RABBITMQ_PASSWORD"),
                           rabbitmq_host=get_env("RABBITMQ_HOST"),
                           rabbitmq_port=get_env("RABBITMQ_PORT"),
                           rabbitmq_path=get_env("RABBITMQ_PATH"),
                           rabbitmq_https=get_env("RABBITMQ_HTTPS"),
                           rabbitmq_exchange=get_env("RABBITMQ_EXCHANGE_NAME"),
                           rabbitmq_delivery_mode=get_env("RABBITMQ_DELIVERY_MODE"),
                           raspberry_name=get_env("RASPBERRY_NAME"))
