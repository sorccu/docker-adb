# docker-adb

This repository contains a [Dockerfile](https://www.docker.io/) for the [Android Debug Bridge](http://developer.android.com/tools/help/adb.html). It gives you access to platform tools such as `adb` and `fastboot`.

## Changes

* _2016-07-02_ The image now uses [Alpine](https://hub.docker.com/_/alpine/) as the base image, making it way smaller. Furthermore, downloading the platform tools is now done in a more cunning way, further removing almost all dependencies and reducing image size. Only platform-tools are now included.
* _2016-07-02_ Due to internal ADB changes our previous start command no longer works in the latest version. The command has been updated, but if you were specifying it yourself, make sure you're using `adb -a -P 5037 server nodaemon`. Do NOT use the `fork-server` argument anymore.
* _2016-07-02_ The `.android` directory path has been fixed. Thanks to @alexislg2 for spotting it!

## Gotchas

* The container needs extended privileges for USB access
* The host's `/dev/bus/usb` must be mounted on the container

## Security

The container is preloaded with an RSA key for authentication, so that you won't have to accept a new key on the device every time you run the container (normally the key is generated on-demand by the adb binary). While convenient, it means that your device will be accessible over ADB to others who possess the key. You can supply your own keys by using `-v /your/key_folder:/root/.android` with `docker run`.

## Updating the platform tools manually

If you feel like the platform tools are out of date and can't wait for a new image, you can update the platform tools with the following command:

```sh
update-platform-tools.sh
```

It's in `/usr/local/bin` and therefore already in `$PATH`.

## Usage

There are various ways to use this image. Some of the possible usage patterns are listed below. It may sometimes be possible to mix them depending on the case. Also, you don't have to limit yourself to the patterns mentioned here. If you can find another way that works for you, go ahead.

### Pattern 1 - Shared network on the same machine (easy)

This usage pattern shares the ADB server container's network with ADB client containers.

Start the server:

```
docker run -d --privileged -v /dev/bus/usb:/dev/bus/usb --name adbd sorccu/adb
```

Then on the same machine:

```
docker run --rm -ti --net container:adbd sorccu/adb adb devices
docker run --rm -i --net container:adbd ubuntu nc localhost 5037 <<<000chost:devices
```

**Pros:**

* No port redirection required
* No need to look up IP addresses
* `adb forward` works without any tricks (but forwards will only be accessible to the client containers)

**Cons:**

* Cannot use bridged (or any other) network on the client container
* Only works if the server and client containers run on the same machine

### Pattern 2 - Host network (easy but feels wrong)

This usage pattern binds the ADB server directly to the host.

Start the server:

```
docker run -d --privileged --net host -v /dev/bus/usb:/dev/bus/usb --name adbd sorccu/adb
```

Then on the same machine:

```
docker run --rm -ti --net host sorccu/adb adb devices
docker run --rm -i --net host ubuntu nc localhost 5037 <<<000chost:devices
```

Or on another machine:

```
docker run --rm -ti sorccu/adb adb -H x.x.x.x -P 5037 devices
```

**Pros:**

* No port redirection required
* No need to look up IP addresses
* `adb forward` works without any tricks (and forwards are visible from other machines)
* No docker network overhead
* ADB server visible from other machines

**Cons:**

* ADB server visible from other machines unless the startup command is modified
* Client containers must always use host networking or know the machine's IP address

### Pattern 3 - Linked containers on the same machine (can be annoying)

This usage pattern shares the ADB server container's network with ADB client containers.

Start the server:

```
docker run -d --privileged -v /dev/bus/usb:/dev/bus/usb --name adbd sorccu/adb
```

Then on the same machine:

```
docker run --rm -ti --link adbd:adbd sorccu/adb \
  sh -c 'adb -H $ADBD_PORT_5037_TCP_ADDR -P 5037 devices'
```

**Pros:**

* No port redirection required
* No need to manually look up IP addresses
* `adb forward` works without any tricks (but forwards will only be accessible to the client containers over the designated IP)

**Cons:**

* Need to always pass the server IP to `adb` with `-H $ADBD_PORT_5037_TCP_ADDR`
* Need to be careful when running the container so that variables get replaced inside the container and not in the calling shell
* Only works if the server and client containers run on the same machine

### Pattern 4 - Remote client

This usage pattern works best when you want to access the ADB server from a remote host.

Start the server:

```
docker run -d --privileged -v /dev/bus/usb:/dev/bus/usb --name adbd -p 5037:5037 sorccu/adb
```

Then on the client host:

```
docker run --rm -ti sorccu/adb adb -H x.x.x.x -P 5037 devices
```

Where `x.x.x.x` is the server host machine.

**Pros:**

* Scales better (can use any number of hosts/clients)
* No network limitations

**Cons:**

* Need to be aware of IP addresses
* Higher latency
* You'll need to make other ports (e.g. from `adb forward`) accessible yourself

## Systemd units

Sample [systemd](https://www.freedesktop.org/wiki/Software/systemd/) units are provided in the [systemd/](systemd/) folder.

| Unit | Role | Purpose |
|------|------|---------|
| [adb-image.service](systemd/adb-image.service) | Support | Pulls the image from Docker Hub. |
| [adbd-container.service](systemd/adbd-container.service) | Support | Creates a container for the ADB daemon based on the adb image, but doesn't run it. |
| [adbd.service](systemd/adbd.service) | Primary | Runs the prepared ADB daemon container and makes sure it stays alive. |

This 3-unit configuration, while slightly complex, offers superior benefits such as incredibly fast start time on failure since everything has already been prepared for `adbd.service` so that it doesn't have to do any extra work. The adb image will only get pulled once at boot time instead of at every launch (or manually by calling `systemctl restart adb-image`, which will also restart the other units).

Copy the units to `/etc/systemd/system/` on your target machine.

Then, enable `adbd.service` so that it starts automatically after booting the machine:

```sh
systemctl enable adbd
```

Finally, either reboot or start the service manually:

```sh
systemctl start adbd
```

If you change the units, don't forget to run `systemctl daemon-reload` or they won't get updated.

## Thanks

* [Jérôme Petazzoni's post on the docker-user forum explaining USB device access](https://groups.google.com/d/msg/docker-user/UsekCwA1CSI/RtgmyJOsRtIJ)
* @sgerrand for [sgerrand/alpine-pkg-glibc](https://github.com/sgerrand/alpine-pkg-glibc)
* @frol for [frol/docker-alpine-glibc](https://github.com/frol/docker-alpine-glibc)

## License

See [LICENSE](LICENSE).
