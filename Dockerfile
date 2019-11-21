FROM golang:1.13.4-alpine3.10

RUN apk add --no-cache git openssh gcc musl-dev jq bash curl openssl

RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 && chmod +x /usr/local/bin/yq

RUN wget -O /tmp/get-helm-3 https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod +x /tmp/get-helm-3 && /tmp/get-helm-3

WORKDIR /helm2cf
ADD ./helm2cf.sh /helm2cf
RUN chmod +x /helm2cf/helm2cf.sh

# Mount point for helm (read)
RUN mkdir -p /helm
# Mount point for manifests (write)
RUN mkdir -p /manifests

ENTRYPOINT ["/helm2cf/helm2cf.sh"]
