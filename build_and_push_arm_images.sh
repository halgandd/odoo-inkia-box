#!/usr/bin/env bash
docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/docker/teclib-box:printer_arm7 ./printer
docker push registry.teclib-erp.com/docker/teclib-box:printer_arm7
docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/docker/teclib-box:config_arm7 ./config
docker push registry.teclib-erp.com/docker/teclib-box:config_arm7
docker buildx build --platform "linux/arm/v7" --load -t registry.teclib-erp.com/docker/teclib-box:cups_arm7 ./cups
docker push registry.teclib-erp.com/docker/teclib-box:cups_arm7