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
      http://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140624.zip && \
    unzip /opt/adt.zip adt-bundle-linux-x86_64-20140624/sdk/platform-tools/adb -d /opt && \
    mv /opt/adt-bundle-linux-x86_64-20140624 /opt/adt && \
    rm /opt/adt.zip && \
    ln -s /opt/adt/sdk/platform-tools/adb /usr/local/bin/adb

# Set up insecure default key
RUN mkdir -m 0750 /.android
ADD files/insecure_shared_adbkey /.android/adbkey
ADD files/insecure_shared_adbkey.pub /.android/adbkey.pub

# Clean up
RUN apt-get -y --purge remove wget unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/cache/apt/*

# Expose default ADB port
EXPOSE 5037

# Start the server by default. This needs to run in a shell or Ctrl+C won't
# work.
CMD /usr/local/bin/adb -a -P 5037 fork-server server
