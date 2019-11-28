from datetime import datetime


from .channels import ProducerChannel
from .exceptions import UnknownQueueError

from .connection_handler import ConnectionHandler
from .producer import Producer
from .worker import Worker

DEFAULT_URL = 'amqp://test:test@localhost:5672/foo-test'
DEFAULT_EXCHANGE = 'FOO-EXCHANGE'
DEFAULT_APP = 'FOO-APPLICATION-ID'
DEFAULT_DELIVERY = 2
STATUS_READY = 'READY'


class BrokerRabbitMQ:
    """Message Broker based on RabbitMQ middleware"""

    def __init__(self, app=None):
        """
        Create a new instance of Broker Rabbit by using
        the given parameters to connect to RabbitMQ.
        """
        self.app = app
        self.connection_handler = None
        self.producer = None
        self.url = None
        self.exchange_name = None
        self.delivery_mode = None
        self.queues = None
        self.on_message_callback = None

    def init_app(self, rabbitmq_url, exchange_name, delivery_mode, queues, on_message_callback):
        """ Init the Broker by using the given configuration instead
        default settings.

        :param app: Current application context
        :param list queues: Queues which the message will be post
        :param callback on_message_callback: callback to execute when new
        message is pulled to RabbitMQ
        """
        self.url = rabbitmq_url
        self.exchange_name = exchange_name
        self.application_id = DEFAULT_APP
        self.delivery_mode = delivery_mode
        self.queues = queues
        self.on_message_callback = on_message_callback

        # Open Connection to RabbitMQ
        self.connection_handler = ConnectionHandler(self.url)
        connection = self.connection_handler.get_current_connection()

        # Setup default producer for broker_rabbit
        channel = ProducerChannel(connection, self.application_id,
                                  self.delivery_mode)
        self.producer = Producer(channel, self.exchange_name)
        self.producer.bootstrap(self.queues)

    def send(self, queue, context={}):
        """Post the message to the correct queue with the given context

        :param str queue: queue which to post the message
        :param dict context: content of the message to post to RabbitMQ server
        """
        if queue not in self.queues:
            error_msg = 'Queue ‘{queue}‘ is not registered'
            raise UnknownQueueError(error_msg)

        message = {
            'created_at': datetime.utcnow().isoformat(),
            'queue': queue,
            'context': context
        }

        return self.producer.publish(queue, message)

    def list_queues(self):
        """List all available queue in the app"""
        for queue in self.queues:
            print('Queue name : `%s`' % queue)

    def start(self, queue):
        """Start worker on a given queue
        :param queue: the queue which you consume message for
        """
        if queue not in self.queues:
            raise RuntimeError('Queue with name`{queue}` not found')

        worker = Worker(connection_handler=self.connection_handler,
                        message_callback=self.on_message_callback, queue=queue)
        print('Start consuming message on the queue %s'%(queue))
        worker.consume_message()
