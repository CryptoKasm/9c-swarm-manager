### Nine Chronicles | Community Tool

# Swarm Manager

Nine Chronicles is a fantasy MMORPG, set in a vast fantasy world powered by groundbreaking blockchain technology, that gives players the freedom to play how they want: exploring, crafting, mining or governing in a uniquely moddable, open-source adventure.

Conquer dangerous dungeons to gather rare resources for trade; specialize in crafting the finest equipment; mine your own income; or pass legislation with the support of other players to inhabit this realm as you see fit.

This project was created to provide an easy solution for those wanting to mine their own income (NCG) via Docker containers. This branch holds automated scripts that setup the required environment to run these containers on both Linux & Windows 10, version 1903 or higher

<br>

#

### Notes:

- **<span style="color:green">TIP:</span> Windows Users: MAKE SURE TO START DOCKER!**

- **<span style="color:red">WARNING:</span> Installing the Swarm Miner enables Hyper-V on Windows. This could cause issues with VMware Workstation if it is installed.**

- **<span style="color:red">WARNING:</span> Some anti-virus software may flag the miner as malicious, please add an exception or disable and retry before contacting support.**

#

<br>

### Features:

- Dockerized image
- Snapshot management
- Auto Updater, based on this URL: https://download.nine-chronicles.com/apv.json
- Auto Restarter
- Monitor miners for errors and responds accordingly

<br>

## Requirements

- For Normal Usage

  - Docker

- For Development
  - VS Code
    - https://code.visualstudio.com/download
  - VS Code Extension: Remote Containers
    - https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

<br>

## Usage

**_Method 1: Deploy via CMD_**

```bash
# Example using PRIVATE_KEY
docker run -d -v "/var/run/docker.sock:/var/run/docker.sock" --env PRIVATE_KEY=000000000000 --env MINERS=1 --name 9c-swarm-manager cryptokasm/9c-swarm-manager:latest
```

<br>

**_Method 2: Deploy via docker-compose.yml_**

```yml
# Example using PRIVATE_KEY
version: '3'

services:
  manager:
    container_name: 9c-swarm-manager
    image: cryptokasm/9c-swarm-manager:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker-host.sock
    environment:
      - PRIVATE_KEY=000000000000
      - MINERS=1
```

```yml
# Default Settings
# Add a setting you would like to change to the environment argument

# Enable/Disable Debugging
DEBUG="1"

# Enable/disable Advanced Debugging
TRACE="0"

# Development mode with less security and a demo account
DEV_MODE="false"

# Disable mining (Node only)
DISABLE_MINING="false"

# Disable PrivateKey at runtime
DISABLE_PRIVATE_KEY="false"

# Nine Chronicles Private Key **KEEP SECRET**
PRIVATE_KEY="PUT_YOUR_PRIVATE_KEY_HERE"

# Amount of miners to deploy
MINERS="1"

# GraphQL Forwarding Port
GRAPHQL_PORT="23062"

# Peer Forwarding Port
PEER_PORT="31235"

# Set MAX RAM Per Miner **PROTECTION FROM MEMORY LEAKS**
RAM_LIMIT="4096M"

# Set MIN RAM Per Miner **SAVES RESOURCES FOR THAT CONTAINER**
RAM_RESERVE="2048M"

# Enable GraphQL Query Commands
AUTHORIZE_GRAPHQL="1"

# Enable/Disable CORS policy
DISABLE_CORS="false"

# Auto-restart after set time (in hours)
AUTO_RESTART="2"

# Filters to GREP out of miner logs (0 None, # of Miner, ALL)
MINER_LOG_FILTERS="ALL"

# Set MINER name (example)
NAME_MINER_1="Joe"
NAME_MINER_2="Joe"
NAME_MINER_3="Joe"
NAME_MINER_4="Joe"
```

```bash
# Development Mode
DEV_MODE="true"

# Automatically enables these settings:
DISABLE_MINING="true"
DISABLE_CORS="true"
GRAPHQL_PORT="23075"
PEER_PORT="31275"

# Enables the use of a DEMO account and ability to disable privatekey
PRIVATE_KEY="DEMO"
or
PRIVATE_KEY="DISABLE"

```

<br>

**_Method 3: Build Image & Deploy_**

```bash
# 1. Clone from Github
  git clone https://github.com/CryptoKasm/9c-swarm-manager.git

# 2. Open project in VS Code

# 3. Click ICON in lower left corner > Remote-Containers: Reopen in container

# 4. Start Developing
- ./swarm-manager.sh          # Runs 9c-swarm-manager
- ./swarm-manager.sh --build  # Builds docker-image
- ./swarm-manager.sh --run    # Runs built docker-image

```

<br>

# Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

<br>

# Community & Support

Come join us in the community Discord server! If you have any questions, don't hesitate to ask!<br/>

- **Planetarium - [Discord](https://discord.gg/k6z2GS4yh2)**

Support & Bug Reports<br/>

- **CrytpoKasm - [Discord](https://discord.gg/k6z2GS4yh2)**

<br>

# License

[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)
