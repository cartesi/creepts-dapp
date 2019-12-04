FROM golang:1.13-alpine as web3-build

RUN apk add --no-cache build-base git sudo

RUN git clone https://github.com/gochain/web3
RUN cd web3 && make install


FROM ethereum/client-go

COPY --from=web3-build /usr/local/bin/web3 /usr/local/bin

RUN apk add --no-cache jq

WORKDIR /root

COPY entrypoint.sh .
COPY genesis.jq .

ENTRYPOINT [ "/root/entrypoint.sh" ]
