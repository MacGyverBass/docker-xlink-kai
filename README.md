# XLink Kai in Docker

This is a Docker image implentation of the Linux XLink Kai binary, designed to be as small and easy to use as possible.

## About XLink Kai

XLink Kai is a global gaming network developed by Team XLink allowing for online play of video games with support for LAN multiplayer modes.
It allows you to play system-link enabled games across the Internet using a network configuration that simulates a local area network (LAN).
More information about XLink Kai can be found on their homepage here: <https://www.teamxlink.co.uk/>

Note that you need to register an XTag on the XLink Kai Homepage before you will be able to play games with others online.
Please make sure to review the information on the official XLink Kai Wiki & FAQ before submitting an issue.

## Running XLink Kai Engine using Docker

First off, there are 4 key things to know that are important when running this Docker image on your system.

* It is best to run this image using `--restart unless-stopped` as kaiengine will sometimes exit when some configuration changes are made, thus by using the restart argument it will restart the container automatically.
* You must use `--cap-add NET_ADMIN` when running this image, otherwise the kaiengine binary will crash.  If your container is set to restart (see above line) it may forever restart due to crashing every time it restarts.
* It is best to run this image using `--network host` or using a macvlan you've previously created that co-exists on your network with your console devices.  This is done so that the kaiengine binary can search the network for your devices and be able to find & connect to them.  Using the default network bridge is not recommended and may not be able to see any devices on your network.
* Lastly it is recommended to store the configuration files the program creates to a host folder, so they are retained if the container is removed/re-added/etc and for easier backup.

Here is a basic example of it running using `host` as the network:

```bash
docker run \
 --detach \
 --restart unless-stopped \
 --cap-add NET_ADMIN \
 --network host \
 --volume /my-data/xlink-config/:/root/.xlink/ \
 --name xlink-kai \
 macgyverbass/xlink-kai:latest
```

The above will run the image as a detached background process using the `--detach` argument.  It then uses `--restart unless-stopped` to automatically restart the container if the kaiengine binary exits or if the system reboots and `--cap-add NET_ADMIN` as noted above.  It uses `--network host` to specify that it will be attaching to the host network, thus being able to see the local network.  It also defines a host folder to store the configuration files (you may use any folder to store the files).  It lastly defines a name to run the container, so Docker doesn't assign it a randomly-generated name (this is also wise to do so you can find the restart/stop/remove the container easier).

You may also choose to run this image using a `docker-compose.yml` file.  Here is an example based upon the above command:

```yml
version: '3'
services:
  xlink-kai:
    restart: unless-stopped
    cap_add:
    - NET_ADMIN
    networks:
    - host
    volumes:
    - /my-data/xlink-config/:/root/.xlink/
    container_name: xlink-kai
    image: macgyverbass/xlink-kai:latest
```

The above `docker-compose.yml` example can be then ran using `docker-compose up -d` to start the container and run as a detached background process.

For additional information on running Docker images and the arguments available, please refer to the official Docker documentation.

## Accessing the XLink Kai Engine Docker from a Web Browser

By default, the XLink Kai Engine hosts a web interface on port 34522.  Simply put in the server IP/hostname with port number 34522 to access the page.  For example, if your server IP is `192.168.0.50`, you would enter `http://192.168.0.50:34522/` into your web browser on the same network to access the XLink Kai Engine web interface.

If you are using a macvlan network and didn't specify an IP address, you may use the following Docker command to read the IP:  (Substituting "xlink-kai" at the end if you run the image with a different container name.)

```bash
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' xlink-kai
```

However, it is recommended that if you are using a macvlan network, to specify the IP address the container will be using.  Please review the official Docker documentation on details of settings up a macvlan and specifying an IP address for more details.

Note that you may change this port to any other unused port of your choice inside the web interface.

## Details on the Docker build

This is a multi-stage Docker image, using `busybox:latest` first to perform the action of finding the latest Debian x86-64 kaiEngine package from the downloads page and downloading/extracting that package.
To make the final build as small as possible, it then builds the image from scratch, adding only the libraries (pulled directly from the `debian:stable-slim` image), a minimal `/etc/services` file, and extracted XLink Kai Engine binary files to the final build.
The end result is a Docker image with only the files necessary to run kaiengine.  There is no shell or other executables within the final image, thus not only is it very small (about 8MB at the time of writing) but also more secure as the only executable binary inside the image is kaiengine itself.

