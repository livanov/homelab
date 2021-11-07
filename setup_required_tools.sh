#!/usr/bin/env bash

if ! command -v docker &> /dev/null
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
    pip3 install docker-compose
    sudo curl -L https://raw.githubusercontent.com/docker/compose/1.27.4/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi
