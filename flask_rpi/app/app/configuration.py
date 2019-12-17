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

	DEBUG = True
	TESTING = True
	SECRET_KEY = "MINHACHAVESECRETA"
	CSRF_ENABLED = True
	GA_MEASUREMENT_ID = os.environ.get("GA_MEASUREMENT_ID")
	RECAPTCHA_CLIENT = os.environ.get("RECAPTCHA_CLIENT")
	RECAPTCHA_SERVER = os.environ.get("RECAPTCHA_SERVER")
	CACHE_TYPE = "simple"
	#Get your reCaptche key on: https://www.google.com/recaptcha/admin/create
	#RECAPTCHA_PUBLIC_KEY = "6LffFNwSAAAAAFcWVy__EnOCsNZcG2fVHFjTBvRP"
	#RECAPTCHA_PRIVATE_KEY = "6LffFNwSAAAAAO7UURCGI7qQ811SOSZlgU69rvv7"

