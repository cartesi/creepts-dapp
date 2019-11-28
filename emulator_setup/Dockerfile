FROM alpine:3.10

# Install command line utilities
RUN apk add --no-cache wget curl

WORKDIR /root
COPY download.sh .
COPY download_asset.sh .

WORKDIR /root/host

# Download files
CMD [ "/root/download.sh" ]
