#!/usr/bin/env python3
import pika, os, time
import base64
from time import sleep
from broker_rabbit import BrokerRabbitMQ
from multiprocessing import Process
import logging
from logging.handlers import RotatingFileHandler
import configparser
import cups
import os
config = configparser.ConfigParser()
config.read('server.ini')

QUEUES = [
    config['rabbitmq'].get('queue_odoo_manul'),
    config['rabbitmq'].get('queue_odoo_colissimo'),
    config['rabbitmq'].get('queue_odoo_chronopost'),
]

rabbitmq_url = 'amqp://{user}:{password}@{host}:{port}/%{path}'.format(
    user=config['rabbitmq'].get('rabbitmq_user'),
    password=config['rabbitmq'].get('rabbitmq_password'),
    host=config['rabbitmq'].get('rabbitmq_host'),
    port=config['rabbitmq'].get('rabbitmq_port'),
    path=config['rabbitmq'].get('rabbitmq_path'),
)

exchange_name = config['rabbitmq'].get('rabbitmq_exchange_name')
delivery_mode=int(config['rabbitmq'].get('rabbitmq_delibery_mode'))

logger = logging.getLogger()
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
# ACTIVITY
file_handler = RotatingFileHandler(config['log'].get('filelog'), 'a', 1000000, 1)
logger.setLevel(eval("logging.%s"%(config['log'].get('log_level'))))
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


def data_process_function(msg):
    logger.info("Data processing of picking name %s and id %s" % (msg.get('picking_name'), msg.get('picking_id')))
    report_name = "%s_%s.%s" % (msg.get('picking_id') or 'picking_id', msg.get('created_at') or 'created_at', msg.get('file_extension') or 'pdf')
    with open(report_name, 'wb') as theFile:
        theFile.write(base64.b64decode(msg.get('data')) if msg.get('file_extension') == 'pdf' else msg.get('data'))
        logger.info("create report name %s" % (report_name))
    logger.info("Send Data to printer %s" % (report_name))
    try:
        conn = cups.Connection()
        conn.printFile(config['printer'].get('%s_printer_name'%(msg.get('queue') or 'pdf')), report_name, "Python_Status_print", {})
        logger.info("Send Data to printer %s" % (report_name))
        os.remove(report_name)
    except:
        logger.info("problem to delete file %s" % (report_name))

def process_message(message):
    data_process_function(message)

def start(queue):
    broker = BrokerRabbitMQ()
    broker.init_app(rabbitmq_url=rabbitmq_url,
                    exchange_name=exchange_name,
                    delivery_mode=delivery_mode,
                    queues=QUEUES, on_message_callback=process_message)
    broker.start(queue)

if __name__ == '__main__':
    for quene in QUEUES:
        prcess = Process(target=start, args=(quene,)).start()