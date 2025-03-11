# Web share Server Deployment Script

## Overview

This script automates the deployment of a simple and easily manageable Caddy server using Docker Compose. 
It includes dynamically generated credentials for **basic authentication**. You have a ./shared/ place to share your files easy.

> http://<your-host>:portnumber/your-auth-shared

(plug and play in 7 sec!) 

## Features

- Easy Docker Compose deployment
- Access with automatically generated credentials
- Dynamic port selection
- Simple file sharing through HTTP

## Requirements

- Docker and Docker Compose installed

## Usage

```bash
bash deploy-fast-webshare.sh
```
or

```bash
chmod +x deploy-fast-webshare.sh
./deploy-fast-webshare.sh
```

Start the service, run:

```bash    
docker compose up -d
```
or
```bash
docker-compose up -d  
```
And now!:

- You can see a random username and password
- Share your files ./shared/ <-- here

Change your Caddy config (API are dissabled, you need restart containeer):

- Caddyfile
- caddy_config (Caddy configuration)" 
- caddy_data (Caddy data)"

Or generate new hashed passwords change your Caddyfile:

```bash
docker run --rm caddy:latest caddy hash-password --plaintext YOUR_PASSWORD
docker compose restart
```

EAAAAAAAASY! ;-)


