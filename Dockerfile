FROM node:12-alpine as onchain

ENV BASE /opt/cartesi
WORKDIR $BASE/share/blockchain

ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc

COPY ./contracts ./contracts
COPY ./migrations ./migrations
COPY ./package.json .
COPY ./truffle-config.js .
COPY ./yarn.lock .

RUN yarn install --flat --production --frozen-lockfile

FROM rust:1.38 as build

ENV BASE /opt/cartesi
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y cmake protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

# install wagyu utility for mnemonic handling
RUN cargo install wagyu

WORKDIR $BASE/dapp

# Compile dependencies
COPY ./dapp/Cargo_cache.toml ./Cargo.toml
RUN mkdir -p ./src && echo "fn main() { }" > ./src/main.rs
RUN cargo build -j $(nproc) --release

WORKDIR $BASE

COPY ./tournament-dlib/ $BASE/tournament-dlib

WORKDIR $BASE/dapp

# Compile creepts
COPY ./dapp/Cargo.toml ./
COPY ./dapp/Cargo.lock ./
COPY ./dapp/src ./src

RUN cargo install -j $(nproc) --path .

# Runtime image
FROM debian:buster-slim as runtime

ENV BASE /opt/cartesi

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates wget gettext jq && \
    rm -rf /var/lib/apt/lists/*

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

WORKDIR /opt/cartesi

# Copy the build artifacts from the build stage
COPY --from=onchain $BASE/share/blockchain $BASE/share/blockchain
COPY --from=build /usr/local/cargo/bin/dapp $BASE/bin/creepts
COPY --from=build /usr/local/cargo/bin/wagyu /usr/local/bin

# Copy dispatcher scripts
COPY ./dispatcher-entrypoint.sh $BASE/bin/
COPY ./config-template.yaml $BASE/etc/creepts/
RUN mkdir -p $BASE/srv/creepts

ENV ETHEREUM_HOST "ganache"
ENV ETHEREUM_PORT "8545"
ENV ETHEREUM_TIMEOUT "120s"

ENTRYPOINT $BASE/bin/dispatcher-entrypoint.sh
