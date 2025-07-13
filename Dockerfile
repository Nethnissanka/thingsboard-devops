FROM rockylinux:9

WORKDIR /tmp

RUN dnf install -y wget rpm java-17-openjdk net-tools && dnf clean all

# Copy RPM
COPY thingsboard.rpm .

# Install ThingsBoard

RUN rpm -Uvh thingsboard.rpm && rm -f thingsboard.rpm

EXPOSE 8080

# Use install script instead of upgrade script for initial setup
CMD ["/usr/share/thingsboard/bin/install/install.sh"]
