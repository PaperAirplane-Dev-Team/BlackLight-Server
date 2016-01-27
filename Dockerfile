FROM base/archlinux:2015.06.01
MAINTAINER Peter Cai "peter@typeblog.net"

# Upgrade the image
RUN pacman -Syu --noconfirm

# Install nodejs and coffee-script
RUN pacman -S --noconfirm nodejs npm coffee-script

# Initialize the environment
WORKDIR /usr/src/bl
COPY node/* /usr/src/bl/
COPY run.sh /usr/src/bl/
RUN cake build && \
  npm install && \
  chmod +x run.sh

# Finalize
EXPOSE 23324
CMD ["./run.sh"]
