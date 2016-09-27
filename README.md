# docker-compose-vault-consul

A simple `docker-compose` setup for a `Consul`-backed `Vault` instance, heavily inspired by and modified from a similar setup by [voxxit](https://gist.github.com/voxxit/dd6f95398c1bdc9f1038).

This provides a simple [Consul](https://www.consul.io/)-backed [Vault](https://www.vaultproject.io/) server, using the official [Consul](https://hub.docker.com/_/consul/) and [Vault](https://hub.docker.com/_/vault/) [Docker](https://www.docker.com/) images, linking them via [docker-compose](https://www.docker.com/products/docker-compose).

# Disclaimer

I am _not_ an expert in Docker, Consul, Vault or security in general. My use-case is in a closed and secure environment (a LAN) where the goal is to centralise and coordinate the use of various secrets for use in automated building/testing (e.g., create product test scripts that query Vault for product authentication details rather than having them hardcoded/embedded in scripts). As such, my requirements are simplicity and robustness, _not_ high security. In other words, use at your own risk!

# Use

The most basic use is to simply copy/rename the sample `docker-compose.sample.yml` file and run `docker-compose up -d` to run and daemonise the two containers. This will expose the Consul web UI on port `8500` and the Vault API on port `8200`. Consul data is stored in a local host volume (under a local `data` directory). The port numbers and use/location of a host volume can, of course, be modified to suit. Further, configuration files for `vault` and `consul` exist within the `config` subdirectory; these are mounted to the containers by the `docker-compose` configuration and again may be modified to suit.

## Helper Scripts

Included are a small set of helper scripts that can either be used directly or as a form of documentation/how-to (again with the caveat that I am _not_ an expert).

### `init.sh`

This will remove any existing instance data (including containers and generated instance/site configuration), create new containers, and initialise the new vault. In the process, it will capture various data and store this in a simple configuration file (`vault.cfg`, stored in a `site` subdirectory). Among the things stored are the name of the vault container, the name of the (`docker`) network used by the containers, the root token, and the unseal keys. This file is a plaintext file (i.e., in no way protected), so _do not_ use this script unless you understand the security implications of storing the root token and unseal keys unprotected!

### `unseal.sh`

Using the data stored in the site configuration (generated above), this script will unseal the vault.

### `create_tokens.sh`

Again, using the data stored in the site configuration, this script will create one or more access tokens with names as supplied on the command-line. e.g., `create_tokens.sh foo bar` will create a token named `foo` and a second named `bar`. Token details will be stored in a site configuration file (`tokens.cfg`). As above, note the security implications of using this script.

## `populate.py`

This script will read a set of secrets from a site JSON file (`secrets.json`) and populate the vault with the content (again using the site configuration where required). The JSON file is expected to be of the following general form:
```
{
    "<category 1>": {
        "<key 1>" : "<value 1>",
        "<key 2>" : "<value 2>"
    },
    "<category 2>": {
        "<subcategory a>": {
            "<key 1>" : "<value 1>",
            "<key 2>" : "<value 2>"
        }
    }
}```

This will create a top-level node `category 1` with two keyed values and a second top-level node `category 2`, containing a sub-node `subcategory a` which contains two (independent) keyed values. There is no restriction on how many levels deep one may use, nor how many nodes or keyed values may be created.

The script largely works by recursively parsing the JSON data and writing a set of secrets whenever a node is found that contains only a dictionary/object of scalars (as is the case with `category 1` and `subcategory a` above).

## `test.sh`

This script simply demonstrates how to use the vault instance, both via the commandline tool and also via the HTTP API. This too uses the site configuration.
