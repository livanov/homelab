#!/usr/bin/env bash

if ! command -v git &> /dev/null
then
    echo "'git' not installed. Installing now ..."
    apt install -y git
fi

if ! command -v docker &> /dev/null
then
    echo "'docker' not installed. Installing now ..."
    curl -fsSL https://get.docker.com | bash
fi

if ! command -v docker-compose &> /dev/null
then
    echo "'docker-compose' not installed. Installing now ..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo curl -L "https://raw.githubusercontent.com/docker/compose/1.27.4/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
fi
