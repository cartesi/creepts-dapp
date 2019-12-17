FROM rust:1.38 as build

ENV BASE /opt/cartesi
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y cmake protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

WORKDIR $BASE

COPY ./tournament-dlib/ $BASE/tournament-dlib

WORKDIR $BASE/dapp

# Compile dependencies
COPY ./dapp/Cargo.toml ./
COPY ./dapp/Cargo.lock ./
RUN mkdir -p ./src && echo "fn main() { }" > ./src/main.rs
RUN cargo build -j $(nproc) --release

# Compile creepts
COPY ./dapp/src ./src

RUN cargo install -j $(nproc) --path .

# Runtime image
FROM debian:buster-slim

ENV BASE /opt/cartesi

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates wget gettext && \
    rm -rf /var/lib/apt/lists/*

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

WORKDIR /opt/cartesi

# Copy the build artifact from the build stage
COPY --from=build /usr/local/cargo/bin/anuto_dapp $BASE/bin/creepts

# Copy dispatcher scripts
COPY ./dispatcher-entrypoint.sh $BASE/bin/
COPY ./config-template.yaml $BASE/etc/creepts/
RUN mkdir -p $BASE/srv/creepts

ENV ETHEREUM_HOST "ganache"
ENV ETHEREUM_PORT "8545"
ENV ETHEREUM_TIMEOUT "120s"

CMD dockerize \
    -wait file:///opt/cartesi/etc/keys/keys_done \
    -wait file:///opt/cartesi/share/blockchain/contracts/deploy_done \
    -wait tcp://${ETHEREUM_HOST}:${ETHEREUM_PORT} \
    -wait tcp://machine-manager:50051 \
    -wait tcp://logger:50051 \
    -timeout ${ETHEREUM_TIMEOUT} \
    $BASE/bin/dispatcher-entrypoint.sh
