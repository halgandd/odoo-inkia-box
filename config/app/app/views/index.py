# -*- encoding: utf-8 -*-
"""
Python Application Template
Licence: GPLv3
"""

from flask import render_template, make_response, request, redirect, flash
from app import app
import cups
import os
import re
import subprocess
from datetime import date
import pika
import json
import docker
from urllib.parse import quote

@app.route('/form/printer_action', methods=['GET', 'POST'])
def printer_action():
    app.logger.info("Printer action")
    data = request.form
    app.logger.info(data)
    if not data.get('print',True):
        app.logger.info("Print")
    if not data.get('cancel',True):
        app.logger.info("Cancel")
    return redirect('/')

@app.route('/action/reload', methods=['GET', 'POST'])
def action_reload():
    app.logger.info("Reload")
    open("/action/reload",'a').close()
    flash('Teclib Box is reloading', "warning")
    return redirect('/')

@app.route('/action/restart', methods=['GET', 'POST'])
def action_restart():
    app.logger.info("Restart")
    open("/action/restart", 'a').close()
    flash('Teclib Box is restarting', "warning")
    return redirect('/')


@app.route('/action/save', methods=['GET', 'POST'])
def action_save():
    app.logger.info("Save configuration")
    def set_env(file, data_form, env_name, var_name, default=""):
        if data_form.get(var_name):
            val = data.get(var_name, default)
            file.write("%s=%s\r\n" % (env_name, val))
            os.environ[env_name] = val

    data = request.form
    app.logger.info(data)
    path = os.environ.get('PATH_ENV_FILE')
    f = open(path, "w+")

    set_env(f, data, "QUEUE_NAMES", "queue_names")
    set_env(f, data, "RABBITMQ_USER", "rabbitmq_user")
    set_env(f, data, "RABBITMQ_PASSWORD", "rabbitmq_password")
    set_env(f, data, "RABBITMQ_HOST", "rabbitmq_host")
    set_env(f, data, "RABBITMQ_PORT", "rabbitmq_port")
    set_env(f, data, "RABBITMQ_PATH", "rabbitmq_path", "/")
    set_env(f, data, "RABBITMQ_EXCHANGE_NAME", "rabbitmq_exchange")
    set_env(f, data, "RABBITMQ_DELIVERY_MODE", "rabbitmq_delivery_mode")
    set_env(f, data, "RABBITMQ_HTTPS", "rabbitmq_https", "1")
    set_env(f, data, "ODOO_HOST", "odoo_host", "")
    set_env(f, data, "ODOO_SSH_PORT_TUNNEL", "odoo_ssh_port_tunnel", "")

    f.write("%s=%s\r\n" % ("FILELOG", os.environ.get("FILELOG")))
    f.write("%s=%s\r\n" % ("LOG_LEVEL", os.environ.get("LOG_LEVEL")))

    f.close()
    flash("Saved configuration", "primary")
    return redirect('/')


@app.route('/')
def index():
    def get_cups_printer():
        app.logger.info("Search Cups devices")
        devices = []
        try:
            cups.setServer(os.environ.get("CUPS_HOST"))
            cups.setUser(os.environ.get("CUPS_USER"))
            cups.setPasswordCB(lambda a: os.environ.get("CUPS_PASSWORD"))
            conn = cups.Connection()
            devices = conn.getPrinters()
        except Exception as e:
            app.logger.error(e)
            flash("Cups Error", "danger")

        return devices

    def get_usb_devices():
        app.logger.info("Search USB devices")
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
                    app.logger.info("USB Device : %s " % dinfo)
        return devices

    def get_messages():
        app.logger.info("Search Messages")
        messages = {}
        https = bool(int(os.environ.get("RABBITMQ_HTTPS", "0"))) and 's' or ''
        user = os.environ.get("RABBITMQ_USER", "")
        password = quote(os.environ.get("RABBITMQ_PASSWORD", ""), safe='')
        host = os.environ.get("RABBITMQ_HOST", "")
        port = os.environ.get("RABBITMQ_PORT", "")
        path = quote(os.environ.get("RABBITMQ_PATH", ""), safe='')
        rabbitmq_url = 'amqp{https}://{user}:{password}@{host}:{port}/{path}'.format(
            https=https,
            user=user,
            password=password,
            host=host,
            port=port,
            path=path,
        )
        app.logger.info("Url %s" % (rabbitmq_url))
        if not host or not user or not password or not path or not port:
            return messages
        try:
            params = pika.URLParameters(rabbitmq_url)
            app.logger.info("RabbitMQ Params : %s", str(params))
            connection = pika.BlockingConnection(params)
            if os.environ.get("QUEUE_NAMES", ""):
                for queue_name in os.environ.get("QUEUE_NAMES", "").split(','):
                    app.logger.info("Check queue %s" % (queue_name))
                    channel = connection.channel()
                    queue = channel.queue_declare(queue=queue_name, durable=True)
                    if queue_name not in messages:
                        messages[queue_name] = {'count': queue.method.message_count, 'messages': []}
                    app.logger.info("%s messages in queue %s" % (queue.method.message_count, queue_name))
                    for i in range(queue.method.message_count):
                        method_frame, header_frame, body = channel.basic_get(queue_name)
                        decoded_message = body.decode()
                        msg = json.loads(decoded_message)
                        app.logger.info("Queue %s : message %s, routing key %s name %s" % (queue_name, i, method_frame.routing_key, msg['name']))
                        channel.basic_nack(method_frame.delivery_tag)
                        messages[queue_name]['messages'].append({'sequence':i+1, 'routing_key':method_frame.routing_key, 'name':msg['name']})
                connection.close()
        except Exception as e:
            app.logger.error(e)
            flash("RabbitMQ Error", "danger")
        return messages

    def get_docker_containers():
        app.logger.info("Get docker containers")
        containers = []
        try:
            client = docker.from_env()
            for container in client.containers.list():
                app.logger.info(container.logs)
                containers.append({
                    'id': container.id,
                    'name': container.name,
                })
        except:
            flash("Docker Error", "danger")
        return containers

    messages = get_messages()
    usb_devices = get_usb_devices()
    cups_printer = get_cups_printer()
    containers = get_docker_containers()
    return render_template("index.html", app=app,
                           messages=messages,
                           usb_devices=usb_devices,
                           cups_printer=cups_printer,
                           queue_names=os.environ.get("QUEUE_NAMES",""),
                           rabbitmq_user=os.environ.get("RABBITMQ_USER",""),
                           rabbitmq_password=os.environ.get("RABBITMQ_PASSWORD",""),
                           rabbitmq_host=os.environ.get("RABBITMQ_HOST",""),
                           rabbitmq_port=os.environ.get("RABBITMQ_PORT", "5671"),
                           rabbitmq_path=os.environ.get("RABBITMQ_PATH", "/"),
                           rabbitmq_https=os.environ.get("RABBITMQ_HTTPS", "1"),
                           rabbitmq_exchange=os.environ.get("RABBITMQ_EXCHANGE_NAME","odoo"),
                           rabbitmq_delivery_mode=os.environ.get("RABBITMQ_DELIVERY_MODE","2"),
                           port_cups=os.environ.get("CUPS_PORT","631"),
                           odoo_host=os.environ.get("ODOO_HOST", ""),
                           odoo_ssh_port_tunnel=os.environ.get("ODOO_SSH_PORT_TUNNEL", ""),
                           containers=containers,
                           )
