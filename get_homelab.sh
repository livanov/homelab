#!/usr/bin/env bash

if ! command -v docker &> /dev/null
then
    echo "'git' not installed. Installing now ..."
    apy install -y git
fi

if [ -d homelab ]
then
    mv homelab homelab_$(date +%Y%m%d)
fi

git clone https://github.com/livanov/homelab.git

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
