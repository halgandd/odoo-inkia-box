#!/usr/bin/env python3
import pika, os, time
import base64
from time import sleep
from broker_rabbit import BrokerRabbitMQ
import logging
from logging.handlers import RotatingFileHandler
import sys
import configparser
import cups
import os

config = configparser.ConfigParser()
config.read('server.ini')

logger = logging.getLogger()
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
# ACTIVITY
file_handler = RotatingFileHandler(config['log'].get('filelog'), 'a', 1000000, 1)
logger.setLevel(eval("logging.%s"%(config['log'].get('log_level'))))
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


def pdf_process_function(msg):
    logger.info("PDF processing of picking name %s and id %s" % (msg.get('picking_name'), msg.get('picking_id')))
    report_name = "%s_%s.pdf" % (msg.get('picking_id') or 'picking_id', msg.get('created_at') or 'created_at')
    with open(report_name, 'wb') as theFile:
        theFile.write(base64.b64decode(msg.get('pdf')))
    logger.info("Send PDF to printer %s" % (report_name))
    try:
        conn = cups.Connection()
        conn.printFile(config['printer'].get('printer_name'), report_name, "Python_Status_print", {})
        os.remove(report_name)
    except:
        logger.info("problem to delete file %s" % (report_name))



def process_message(message):
    print ("message %s" %(message))
    pdf_process_function(message)
    sleep(1)


rabbitmq_url = 'amqp://{user}:{password}@{host}:{port}/%{path}'.format(
    user=config['rabbitmq'].get('rabbitmq_user'),
    password=config['rabbitmq'].get('rabbitmq_password'),
    host=config['rabbitmq'].get('rabbitmq_host'),
    port=config['rabbitmq'].get('rabbitmq_port'),
    path=config['rabbitmq'].get('rabbitmq_path'),
)

broker = BrokerRabbitMQ()
broker.init_app(rabbitmq_url=rabbitmq_url,
                exchange_name=config['rabbitmq'].get('rabbitmq_exchange_name'),
                delivery_mode=int(config['rabbitmq'].get('rabbitmq_delibery_mode')),
                queues=[config['rabbitmq'].get('queue_odoo_manul')], on_message_callback=process_message)

while True:
    logger.info("Waiting pdf report")
    broker.start(queue=config['rabbitmq'].get('queue_odoo_manul'))
