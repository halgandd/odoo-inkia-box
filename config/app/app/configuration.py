# -*- encoding: utf-8 -*-
"""
Python Application Template
Licence: GPLv3
"""
import os

class Config(object):
	COMPRESS_MIMETYPES = ['text/html', 'text/css', 'text/xml', 'application/json', 'application/javascript']
	COMPRESS_LEVEL = 6
	COMPRESS_MIN_SIZE = 500
	TESTING = True
	CSRF_ENABLED = True
	CACHE_TYPE = "simple"
