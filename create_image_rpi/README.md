# Create Image Raspberry


## Generation image Raspberry

This Raspberry Image is fully ready to run Docker images.

The docker images stored in ./docker are copied in hypriot images and loadded at boot.
To prepare the docker directory:
    * ./docker_save_images.sh
    
    
To execute some cmd on image before real boot, edit the ./init_static_hypriot.sh
For example,

    apt-get update
will same time.

To configure the raspeberry initialization, file the teclib_userdata.yml
You can set users and files to create on startup.




    ./sudo ./fast_hypriot_image_static.sh
    ./sudo ./fast_hypriot_image_static.sh -n -e






## Build ARM Docker image

In odoo-box, to install docker 19.3ARM buildx

    build_docker_arm.sh -i

To build ARM images:

    build_docker_arm.sh 




















