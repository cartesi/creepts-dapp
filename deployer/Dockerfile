FROM node:12-alpine

# install dockerize, as we need to wait on ganache to be responding
RUN apk add --no-cache \
    build-base \
    git \
    openssl \
    python \
    python-dev \
    py-pip

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

RUN yarn global add truffle@5.1.6
RUN yarn add @truffle/hdwallet-provider@1.0.28
RUN yarn add @truffle/contract@4.1.3

# must create base dir before switching to user node, so its owned by root
WORKDIR /usr/src/app

COPY ./contracts ./contracts
COPY ./migrations ./migrations
COPY ./truffle-config.js .
COPY ./package.json .
COPY ./yarn.lock .

ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
RUN yarn install --production --frozen-lockfile
RUN find node_modules/@cartesi

COPY deployer/migrate.sh .
COPY deployer/unlockAccount.js .
COPY deployer/files .

ENV ETHEREUM_HOST "ganache"
ENV ETHEREUM_PORT "8545"
ENV ETHEREUM_TIMEOUT "10s"
ENV ETHEREUM_NETWORK "development"

CMD dockerize \
    -wait tcp://${ETHEREUM_HOST}:${ETHEREUM_PORT} \
    -timeout ${ETHEREUM_TIMEOUT} \
    ./migrate.sh \
    && touch build/contracts/deploy_done
