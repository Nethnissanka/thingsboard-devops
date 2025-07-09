# File: Dockerfile.tb-server
FROM rockylinux:9

# 1) Install Java and other prerequisites
RUN dnf install -y java-17-openjdk wget net-tools runuser && \
    dnf clean all

# 2) Copy the ThingsBoard 4.0 RPM into the image
COPY thingsboard-4.0.rpm /tmp/

# 3) Install the RPM
RUN rpm -Uvh /tmp/thingsboard-4.0.rpm && \
    rm -f /tmp/thingsboard-4.0.rpm

# 4) Patch the upgrade script so it doesn't prompt for a password
RUN sed -i \
      -e 's|su - thingsboard -c|runuser -u thingsboard --|' \
      /usr/share/thingsboard/bin/install/upgrade.sh

# 5) Ensure the logs directory exists and is owned by the TB user
RUN mkdir -p /var/log/thingsboard && \
    chown -R thingsboard:thingsboard /var/log/thingsboard

# 6) Run the upgrade (from 3.9.x to 4.0) non‑interactively
RUN /usr/share/thingsboard/bin/install/upgrade.sh

# 7) Switch to the unprivileged thingsboard user
USER thingsboard

# 8) Expose the usual ports
EXPOSE 8080 1883 5683 5685

# 9) Start ThingsBoard on container run
CMD ["java", "-jar", "/usr/share/thingsboard/bin/thingsboard.jar"]
