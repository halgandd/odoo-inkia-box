#!/usr/bin/env python3
from setuptools import setup, find_packages

version = open('VERSION').read().strip()
download_url = "https://gitlab.teclib-erp.com/teclib/odoo-box"
with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="broker_rabbit",
    version=version,
    packages=find_packages(),
    install_requires=[
        'pika'],
    author="https://gitlab.teclib-erp.com/teclib/odoo-box",
    author_email="ahilali@teclib.com",
    description="A python interface to rabbitmq",
    include_package_data=True,
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://gitlab.teclib-erp.com/teclib/odoo-box",
    download_url=download_url,
    keywords=['library', 'rabbitmq',],
)

