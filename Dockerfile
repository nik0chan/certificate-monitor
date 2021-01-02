FROM debian:stable-slim

ARG DEBIAN_FRONTEND=noninteractive

LABEL MAINTAINER Nico <nik0chan@hotmail.com>

RUN apt update && \ 
    apt install -y original-awk git wget 
    
WORKDIR /root 

RUN wget https://raw.githubusercontent.com/nik0chan/certificate-monitor/main/check_certificate_expiration.sh -O /usr/local/bin/check_certificate_expiration.sh && \ 
    wget https://raw.githubusercontent.com/nik0chan/certificate-monitor/main/html.awk -O /root/html.awk && \
    chmod +x /usr/local/bin/check_certificate_expiration.sh

ENTRYPOINT ["/usr/local/bin/check_certificate_expiration.sh"]
