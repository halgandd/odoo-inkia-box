#!/usr/bin/env python3
import base64
from time import sleep
import pika
import logging
from logging.handlers import RotatingFileHandler
import cups
import os
import json
import sys
from functools import partial
import threading, time
from urllib.parse import quote

########################################################################################################################
# LOGGING
########################################################################################################################
logging.getLogger("pika").setLevel(logging.WARNING)
logger = logging.getLogger()
logger.setLevel(eval("logging.%s"%(os.environ.get("LOG_LEVEL", "INFO") )))
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(eval("logging.%s"%(os.environ.get("LOG_LEVEL", "INFO") )))
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

########################################################################################################################
# ENV
########################################################################################################################
if not os.environ.get("QUEUE_NAMES",""):
    logger.error("Queue Error")
    exit(1)

queues = os.environ.get("QUEUE_NAMES","").split(',')
user =  os.environ.get("RABBITMQ_USER")
password =  quote(os.environ.get("RABBITMQ_PASSWORD"), safe='')
host =  os.environ.get("RABBITMQ_HOST")
port =  os.environ.get("RABBITMQ_PORT")
path =  quote(os.environ.get("RABBITMQ_PATH"), safe='')
https = os.environ.get("RABBITMQ_HTTPS")
exchange_name =  os.environ.get("RABBITMQ_EXCHANGE_NAME") or ''
delivery_mode =  os.environ.get("RABBITMQ_DELIVERY_MODE") or 2

########################################################################################################################
# CONNECTION
########################################################################################################################
rabbitmq_url = 'amqp{https}://{user}:{password}@{host}:{port}/{path}'.format(
    https=bool(int(https)) and 's' or '',
    user=user,
    password=password,
    host=host,
    port=port,
    path=path,
)

########################################################################################################################
# PROCESS
########################################################################################################################
def process_message(body):
    try:
        if body:
            decoded_message = body.decode()
            msg = json.loads(decoded_message)
            logger.info(">>>>>>>%s" % (msg.get('object_id')))
            logger.info("Data processing of picking name %s and id %s" % (msg.get('name'), msg.get('object_id')))
            printer_name = msg.get('printer_name')
            printer_options = msg.get('printer_options', {}) or {}
            # Filename
            report_name = "/tmp/printed/%s_%s.%s" % (
            msg.get('object_id') or 'object_id', msg.get('created_at') or 'created_at', msg.get('file_extension') or 'pdf')
            report_name = report_name.replace(" ","").replace("-","").replace(":","")
            # Create local file
            with open(report_name, "wb") as theFile:
                theFile.write(
                    base64.b64decode(msg.get('data')))
                logger.info("create report name %s" % (report_name))
            theFile.close()
            # Cups Connection
            cups.setServer(os.environ.get("CUPS_HOST"))
            cups.setUser(os.environ.get("CUPS_USER"))
            cups.setPasswordCB(lambda a: os.environ.get("CUPS_PASSWORD"))
            conn = cups.Connection()
            # Cups print
            logger.info("Send Data %s to printer %s options %s" % (os.path.abspath(report_name), printer_name, printer_options))
            conn.printFile(printer_name, os.path.abspath(report_name), "Python_Status_print", printer_options)
            logger.info("Printing %s %s" % (report_name, printer_name))
            # Remove File
            # os.remove(report_name)
            logger.info("<<<<<<<%s" % (msg.get('object_id')))
            sleep(2)
    except Exception as e:
        logger.error(e, exc_info=True)

def callback(channel, method, properties, body):
    try:
        process_message(body)
        channel.basic_ack(method.delivery_tag)
    except:
        channel.basic_nack(method.delivery_tag, requeue=False)


def run():
    params = pika.URLParameters(rabbitmq_url)
    logger.info("RabbitMQ Params : %s", str(params))
    connection = pika.BlockingConnection(params)
    for queue in queues:
        logger.info("Start consuming %s" %(queue))
        channel = connection.channel()
        channel.queue_declare(queue=queue, durable=True)
        callback2 = partial(callback)
        channel.basic_consume(queue=queue, on_message_callback=callback2, auto_ack=False)
        thread = threading.Thread(target=channel.start_consuming)
        thread.start()

run()
