# Creepts

## Getting Started

### Requirements

- docker
- docker-compose
- jinja2

### Running

To run execute:
```
jinja2 -D num_players=2 docker-compose-template.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - up --build
```

To run with `geth` instead of `ganache`:

To run execute:
```
jinja2 -D num_players=2 docker-compose-template-geth.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - up --build
```


This environment is still using private assets, like:

* private docker images from Docker Hub
* private NPM package from `https://npmjs.com`
* private assets from GitHub releases at `cartesi-corp`

So you need to:

* Do a [docker login](https://docs.docker.com/engine/reference/commandline/login/) before launching the environment
* [Create a NPM token](https://docs.npmjs.com/creating-and-viewing-authentication-tokens) and specifying it in the command line above
* [Create a GitHub personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) and specify it in the command line above

Once we create a public release of the application we won't need this anymore.

To shutdown:
```
jinja2 -D num_players=2 docker-compose-template.yml | NPM_TOKEN=<npm_token> GITHUB_TOKEN=<github_token> docker-compose -f - down -v
```

You can follow the output of a docker instance with:
```
docker logs -f [name of the instance]
```
