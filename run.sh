#!/bin/bash

# Private tokens
sed -i "s/WEIBO_ACCESS_TOKEN/${WEIBO_ACCESS_TOKEN}/g" out/config.json
sed -i "s/GITHUB_ACCESS_TOKEN/${GITHUB_ACCESS_TOKEN}/g" out/config.json
sed -i "s/GITHUB_USER_AGENT/${GITHUB_USER_AGENT}/g" out/config.json

# Start the Service
node out/server.js
