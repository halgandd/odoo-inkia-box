#!/usr/bin/env python3
import base64
from time import sleep
from broker_rabbit import BrokerRabbitMQ
import logging
from logging.handlers import RotatingFileHandler
import cups
import os

queue = os.environ.get("QUEUE_NAME")
user =  os.environ.get("RABBITMQ_USER")
password =  os.environ.get("RABBITMQ_PASSWORD")
host =  os.environ.get("RABBITMQ_HOST")
port =  os.environ.get("RABBITMQ_PORT")
path =  os.environ.get("RABBITMQ_PATH")
exchange_name =  os.environ.get("RABBITMQ_EXCHANGE_NAME")
delivery_mode =  os.environ.get("RABBITMQ_DELIVERY_MODE")
logfile =  os.environ.get("FILELOG")
log_level =  os.environ.get("LOG_LEVEL")
printer_name = os.environ.get("PRINTER_NAME")

rabbitmq_url = 'amqp://{user}:{password}@{host}:{port}/%{path}'.format(
    user=user,
    password=password,
    host=host,
    port=port,
    path=path,
)

logger = logging.getLogger()
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
# ACTIVITY
file_handler = RotatingFileHandler(logfile, 'a', 1000000, 1)
logger.setLevel(eval("logging.%s"%(log_level)))
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


def process_message(msg):
    logger.info("Data processing of picking name %s and id %s" % (msg.get('picking_name'), msg.get('picking_id')))
    report_name = "%s_%s.%s" % (msg.get('picking_id') or 'picking_id', msg.get('created_at') or 'created_at', msg.get('file_extension') or 'pdf')
    mode = "wb" if msg.get('file_extension') in ['pdf','PDF'] else "w+"
    with open(report_name, mode) as theFile:
        theFile.write(base64.b64decode(msg.get('data')) if msg.get('file_extension') in ['pdf','PDF'] else msg.get('data'))
        logger.info("create report name %s" % (report_name))
    theFile.close()
    try:
        conn = cups.Connection()
        conn.printFile(printer_name, report_name, "Python_Status_print", {})
        logger.info("Send Data to printer %s" % (report_name))
    except:
        logger.info("printer problem %s" % (report_name))
    os.remove(report_name)
    sleep(2)

def init_app():
    broker = BrokerRabbitMQ()
    broker.init_app(rabbitmq_url=rabbitmq_url,
                    exchange_name=exchange_name,
                    delivery_mode=delivery_mode,
                    queues=[queue], on_message_callback=process_message)
    return broker


def main():
    broker = init_app()
    broker.start(queue)


if __name__ == '__main__':
    main()
