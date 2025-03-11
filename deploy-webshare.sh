#!/bin/bash

# ==============================================================
# Server Deployment Script
# 
# This script automates the deployment of a Caddy server
# with basic authentication and dynamically generated credentials.
# It uses Docker Compose for easy management.
#
# Author: Joan Puiggali Kopernix
# License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
# You are free to use, share, and modify this script as long as
# you give appropriate credit, provide a link to the license,
# indicate if changes were made, and do not remove my name.
# License URL: https://creativecommons.org/licenses/by-sa/4.0/
# ==============================================================

# Prompt the user for the port on which Caddy should listen
echo -n "Enter the port for Caddy to listen on: "
read port

# Define container name based on port
container_name="caddy-${port}"

# Create necessary folders to store shared files and Caddy configuration
mkdir -p ./shared ./caddy_data ./caddy_config

# Generate a random username in the format userXXX
# Choose a random number between 100 and 999 and concatenate with 'user'
number=$(shuf -i 100-999 -n 1)
user="user${number}"

# Generate a random 12-character password including at least one dash (-) and not starting with '-'
while true; do
    # Generate a random 12-character alphanumeric string including at least one dash (-)
    password=$(< /dev/urandom tr -dc 'A-Za-z0-9-' | head -c12)
    # Verify the password contains at least one dash (-) and doesn't start with '-'
    if [[ "$password" == *"-"* && "${password:0:1}" != "-" ]]; then
        break
    fi
done

# Display the generated username and password
echo "========================================="
echo " GENERATED CREDENTIALS "
echo "========================================="
echo "User: $user Password: $password"
echo ""
echo "Generate new hashed passwords:"
echo "docker run --rm caddy:latest caddy hash-password --plaintext YOUR_PASSWORD"
echo "========================================="

# Generate the hashed password using caddy hash-password inside a temporary container
hashed_password=$(docker run --rm caddy:latest caddy hash-password --plaintext "$password")

# Create the Caddyfile with Caddy configuration
cat <<EOL > Caddyfile
{
    email admin@example.com
}

:${port} {
    root * /srv/shared  # Set server root to the shared folder
    file_server browse  # Enable file browsing in the browser
    basic_auth * {
        # Generate new password
        # docker run --rm caddy:latest caddy hash-password --plaintext YOUR_PASSWORD
        $user $hashed_password  # Configure basic authentication with generated credentials
    }
    # tls internal  # Use Caddy's internal TLS for encrypted connections
}
EOL

# Create docker-compose.yml with service configuration
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ${container_name}:
    image: caddy:latest  # Caddy image from Docker Hub
    container_name: ${container_name}  # Container name based on the port
    restart: unless-stopped  # Restart the container unless stopped manually
    ports:
      - "${port}:${port}"  # Expose dynamic port
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro  # Mount configuration file
      - ./shared:/srv/shared:ro  # Shared folder to serve files
      - ./caddy_data:/data  # Caddy data storage
      - ./caddy_config:/config  # Persistent Caddy configuration
    environment:
      - CADDY_ADMIN_DISABLED=true  # Disable Caddy admin API
EOL

# Get public IP if available
public_ip=$(curl -s ifconfig.me)
if [[ $public_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Public IP detected: $public_ip"
else
    public_ip="Not detected"
fi

# Final message showing deployment details
echo "========================================="
echo " CADDY DEPLOYMENT INFORMATION "
echo "========================================="
echo "Folders created:"
echo " - shared (Files served by Caddy)"
echo " - caddy_data (Caddy data)"
echo " - caddy_config (Caddy configuration)"
echo " - Caddyfile (your Caddyfile!"
echo ""
echo "Copy files to serve into: ./shared"
echo ""
echo "The server is configured to listen on port: ${port}"
echo "You can access it at: http://$public_ip:${port}"
echo "(If public IP isn't available, use the server's local IP)"
echo ""
echo "========================================="
echo "To start the service, run:"
echo "docker compose up -d"
echo "========================================="
