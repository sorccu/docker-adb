FROM ubuntu:14.04
MAINTAINER Simo Kinnunen

# Stop debconf from complaining about missing frontend
ENV DEBIAN_FRONTEND noninteractive

# 32-bit libraries and build deps for ADB
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -y install libc6:i386 libstdc++6:i386 && \
    apt-get -y install wget unzip

# Install ADB
RUN wget --progress=dot:giga -O /opt/adt.zip \
      http://dl.google.com/android/adt/22.6.2/adt-bundle-linux-x86_64-20140321.zip && \
    unzip /opt/adt.zip adt-bundle-linux-x86_64-20140321/sdk/platform-tools/adb -d /opt && \
    mv /opt/adt-bundle-linux-x86_64-20140321 /opt/adt && \
    rm /opt/adt.zip

# Ctrl+C will not work unless ADB is run in a shell. We also need to use both
# CMD and ENTRYPOINT for idiomatic style (i.e. passing arguments directly to
# the adb binary). A simple wrapper script will allow us to do that.
RUN echo '#!/bin/sh\n/opt/adt/sdk/platform-tools/adb "$@"' > /usr/local/bin/adb && \
    chmod +x /usr/local/bin/adb

# Clean up
RUN apt-get -y --purge remove wget unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/cache/apt/*

# Expose default ADB port
EXPOSE 5037

# Start the server by default
CMD ["-a", "-P", "5037", "fork-server", "server"]

ENTRYPOINT ["/usr/local/bin/adb"]
