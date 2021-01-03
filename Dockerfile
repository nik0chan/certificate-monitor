FROM debian:stable-slim

ARG DEBIAN_FRONTEND=noninteractive

LABEL MAINTAINER Nico <nik0chan@hotmail.com>

WORKDIR /root

RUN apt update && \ 
    apt install -y original-awk git wget netcat && \
    rm -rf /var/lib/apt /var/lib/dpkg /var/cache/apt /usr/share/doc /usr/share/man /usr/share/info && \
    wget https://raw.githubusercontent.com/nik0chan/certificate-monitor/main/check_certificate_expiration.sh -O /usr/local/bin/check_certificate_expiration.sh && \ 
    wget https://raw.githubusercontent.com/nik0chan/certificate-monitor/main/html.awk -O /root/html.awk && \
    chmod +x /usr/local/bin/check_certificate_expiration.sh && \ 
    rm -rf /var/lib/apt /var/lib/dpkg /var/cache/apt /usr/share/doc /usr/share/man /usr/share/info 

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/check_certificate_expiration.sh"]
