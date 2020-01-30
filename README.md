# Creepts

## Getting Started

### Requirements

- Docker
- docker-compose
- node 12.x
- yarn
- jinja2

### Cloning

Make sure to include the submodules:
```
git clone --recurse-submodules ssh://github.com/cartesi/creepts-dapp.git
```
or using the http address:
```
git clone --recurse-submodules https://github.com/cartesi/creepts-dapp.git
```

### Running

To run execute:
```
% docker build . -t cartesi/creepts
% yarn
% rm deploy_done
% jinja2 -D num_players=2 docker-compose-template.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - up --build
```

To run with `geth` instead of `ganache`:
```
% docker build . -t cartesi/creepts
% yarn
% rm deploy_done
% jinja2 -D num_players=2 docker-compose-template-geth.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - up --build
```

This environment is still using private assets, like:

* private docker images from Docker Hub
* private NPM package from `https://npmjs.com`
* private assets from GitHub releases

So you need to:

* Do a [docker login](https://docs.docker.com/engine/reference/commandline/login/) before launching the environment
* [Create a NPM token](https://docs.npmjs.com/creating-and-viewing-authentication-tokens) and specifying it in the command line above
* [Create a GitHub personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) and specify it in the command line above

Once we create a public release of the application we won't need this anymore.

To shutdown:
```
% jinja2 -D num_players=2 docker-compose-template.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - down -v
```

You can follow the output of a docker instance with:
```
% docker logs -f [name of the instance]
```

This will run an environment connected to a private net (ganache or geth), with no tournaments deployed.
To deploy a new tournament you need to run the `instantiate_tournament.js` truffle script. To do this you need to have `truffle` installed, and run:

```
% truffle exec instantiate_tournaments.js --network development --level 0 --commit-duration 200 --epoch-duration 200 --match-duration 90 --round-duration 45

    -l, --level <level>: Level number [0-7]
    --commit-duration <duration>: Duration in seconds of commit phase
    --epoch-duration <duration>: Duration in seconds of epoch phase
    --match-duration <duration>: Duration in seconds of match phase
    --round-duration <duration>: Duration in seconds of round phase
```
This will print something like this:

```
Using network 'development'.

Creating tournament for level 0 with commit duration of 200 seconds
MatchManagerInstantiator => 0x3068E180Cb7440f0E01F2d6EEa1aA0E146A619F8
RevealInstantiator => 0x70836Bd7fbF1a13fD83396A9638b40088189A978
Step => 0xAAa6B33bDeD121609835aD13f88018564FbbA7D3
DApp => 0x5A3E31d6855810E2fe8FE5135B6d086837fCEC88
Tournament created: 0xa7a7e33a72435916ce2e3643dacccb101af362de8cfe0d5b27ba4acd2df60b24
```

This new tournament will be created in commit phase. To simulate a post of a log to this tournament you need a `0.json.br.cpio` file in hand, and call the dispatcher by using the `dispatcher-post.sh` script.

```
% ./dispatcher-post.sh localhost:3001 dapp_data_0/0.json.br.cpio
Committing log hash: fe7a808b870492a94337d0c3682a3030029d9f479a93c2b2d162f79638850d01 to dispatcher: localhost:3001...
{"status":"ok"}
Done!
```

#### Running on Testnet

Cartesi will provided a docker image called `cartesi/creepts-onchain` with references to pre-deployed contracts to the testnets `ropsten`, `kovan` and `rinkeby`. So in order to run the cartesi node on your machine you need to create an ethereum wallet, put some funds on it, and run it using the following commands:

```
% export MNEMONIC="<mnemonic>"
% docker-compose up
```

You don't need a ethereum node, by running the above commands you will be using a shared Infura node provided by Cartesi. This may change in the future.

If you want to deploy your own contracts you can build a docker image by doing the following command:

```
docker build . -t cartesi/creepts-onchain -f Dockerfile.onchain --build-arg MNEMONIC="<mnemonic>" --build-arg PROJECT_ID=<infura_project_id>
````
