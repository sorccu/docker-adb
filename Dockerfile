FROM ubuntu:14.04
MAINTAINER Simo Kinnunen

# Stop debconf from complaining about missing frontend
ENV DEBIAN_FRONTEND noninteractive

# 32-bit libraries and deps for ADB
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -y install libc6:i386 libstdc++6:i386 && \
    apt-get -y install wget unzip

# Install ADB
RUN wget --progress=dot:giga -O /opt/adt.zip http://dl.google.com/android/adt/22.6.2/adt-bundle-linux-x86_64-20140321.zip && \
    unzip /opt/adt.zip adt-bundle-linux-x86_64-20140321/sdk/platform-tools/adb -d /opt && \
    ln -s /opt/adt-bundle-linux-x86_64-20140321/sdk/platform-tools/adb /usr/local/bin/adb && \
    rm /opt/adt.zip

# Clean up
RUN apt-get -y --purge remove wget unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/cache/apt/*

EXPOSE 5037

# Ctrl+C will not work unless ADB is run in a shell
CMD adb -a -P 5037 fork-server server
