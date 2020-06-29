#!/usr/bin/env bash

docker buildx use armbuilder

docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/teclib/odoo-box:printer_arm7 ./printer
docker push registry.teclib-erp.com/teclib/odoo-box:printer_arm7
docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/teclib/odoo-box:config_arm7 ./config
docker push registry.teclib-erp.com/teclib/odoo-box:config_arm7
docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/teclib/odoo-box:cups_arm7 ./cups
docker push registry.teclib-erp.com/teclib/odoo-box:cups_arm7
