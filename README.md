# docker-compose-vault-consul

A simple docker-compose setup for a Consul-backed Vault instance, heavily inspired by and modified from a similar setup by [voxxit](https://gist.github.com/voxxit/dd6f95398c1bdc9f1038).

This provides a simple [Consul](https://www.consul.io/)-backed [Vault](https://www.vaultproject.io/) server, using the official [Consul](https://hub.docker.com/_/consul/) and [Vault](https://hub.docker.com/_/vault/) [Docker](https://www.docker.com/) images, linking them via [docker-compose](https://www.docker.com/products/docker-compose).

# Disclaimer

I am _not_ an expert in Docker, Consul, Vault or security in general. My use-case is in a closed and secure environment (a workplace LAN) where the goal is to centralise and coordinate the use of various secrets for use in automated testing (e.g., create product test scripts that query Vault for product authentication details rather than having them hardcoded/embedded in scripts). As such, my requirements are simplicity and robustness, _not_ high security. In other words, use at your own risk!

# Use

The most basic use is to simply run `docker-compose up -d` to run and daemonise the two containers. This will expose the Consul web UI on port 8500 and the Vault API on port 8200. As per the official Consul image, data is stored in a container volume and so will survive container restarts.

Included are a pair of testing/demonstration scripts. The first, `init.sh`, will kill and remove existing containers (allowing a clean starting point), bring up the containers, then initialise and unseal the vault, using the CLI tool via docker. This script also stores the vault keys and root authentication token in a local config file. The second script, `test.sh`, uses the stored configuration, and authenticates, performs a write and performs a read via both CLI and HTTP (via `curl`) interfaces. These scripts are intended to simply demonstrate vault access though the two core means (CLI and HTTP APIs).
