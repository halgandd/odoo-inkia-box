#!/usr/bin/env python3
import base64
from time import sleep
from broker_rabbit import BrokerRabbitMQ
import logging
from logging.handlers import RotatingFileHandler
import cups
import os
from multiprocessing import Process
queues = ['colissimo']
queues = os.environ.get("QUEUE_NAMES").split(',')
user =  os.environ.get("RABBITMQ_USER")
password =  os.environ.get("RABBITMQ_PASSWORD")
host =  os.environ.get("RABBITMQ_HOST")
port =  os.environ.get("RABBITMQ_PORT")
path =  os.environ.get("RABBITMQ_PATH")
https = os.environ.get("HTTPS")
exchange_name =  os.environ.get("RABBITMQ_EXCHANGE_NAME") or ''
delivery_mode =  os.environ.get("RABBITMQ_DELIVERY_MODE") or 2
logfile =  os.environ.get("FILELOG") or '/tmp/odoo.log'
log_level =  os.environ.get("LOG_LEVEL") or 'INFO'
printer_name = os.environ.get("PRINTER_NAME")

rabbitmq_url = 'amqp{https}://{user}:{password}@{host}:{port}/%{path}'.format(
    https=eval(https) and 's' or '',
    user=user,
    password=password,
    host=host,
    port=port,
    path=path,
)

rabbitmq_url = 'amqp://zzjkzkee:lDtW8VuBUEUiSTFc-oA09DFctJ3j971u@clam.rmq.cloudamqp.com/zzjkzkee'
logger = logging.getLogger()
formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
# ACTIVITY
file_handler = RotatingFileHandler(logfile, 'a', 1000000, 1)
logger.setLevel(eval("logging.%s"%(log_level)))
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)


def process_message(msg):
    printer_name = msg.get('printer_name')
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
                    queues=queues, on_message_callback=process_message)
    return broker


def start(queue):
    broker = init_app()
    broker.start(queue)

def main():
    start('colissimo')

    # for quene in queues:
    #     Process(target=start, args=(quene,)).start()


if __name__ == '__main__':
    main()