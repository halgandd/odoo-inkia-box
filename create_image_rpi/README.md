# Create Image Raspberry


## Generation image Raspberry

This Raspberry Image is fully ready to run Docker images.

The docker images stored in ./docker are copied in hypriot images and loadded at boot.
To prepare the docker directory:
    * ./docker_save_images.sh
    
    
To configure the raspeberry initialization, file the teclib_userdata.yml
You can set users and files to create on startup.
docker-compose files are set in teclib_userdata.yml

./sudo ./fast_hypriot_image.sh

Then flash the hypriot_teclib.img image on SD card.



# A fastest script (dev in progress)

    ./sudo ./fast_hypriot_image_static.sh
    ./sudo ./fast_hypriot_image_static.sh -n -e

To execute some cmd on image before real boot, edit the ./init_static_hypriot.sh
For example,

    apt-get update
will save time.



# After first boot

To load docker images:

    cd ./home/pi
    sudo ./init_hypriot_docker.sh 

(This services should be start at boot)

    sudo /etc/init.d/run_teclib_docker
    sudo /etc/init.d/run_teclib_docker


## Build ARM Docker image

In odoo-box, to install docker 19.3ARM buildx

    build_docker_arm.sh -i

To build ARM images:

    /odoo-box/build_docker_arm.sh 



# to connect to raspberry:
    ssh pirate@172.28.215.139    
    password : hypriot

# To Create a config.json (for docker login)
    sudo docker login registry.teclib-erp.com

# Install Portainer
    sudo docker pull hypriot/rpi-portainer
    sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock hypriot/rpi-portainer

# Web access:

Portainer: http://172.28.215.139:9000

Cups: http://172.28.215.139:631/
login: print
password: print

Flask: http://172.28.215.139:8050/




















