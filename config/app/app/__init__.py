# -*- encoding: utf-8 -*-
"""
Python Application Template
Licence: GPLv3
"""

from flask import Flask
from flask_compress import Compress
from flask_assets import Environment, Bundle
from flask_caching import Cache

app = Flask(__name__)
app.config.from_object('app.configuration.Config')

app.cache = Cache(app)
Compress(app)

# app.config['ASSETS_DEBUG'] = True

assets = Environment()
assets.init_app(app)

from app import views

