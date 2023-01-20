#!/bin/sh
set -ex
# Check whether the architecture is x86_64 or arm64
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="amd64"
else
    ARCH="arm64"
fi
# Check whether the OS is Linux or macOS
if [ "$(uname)" = "Linux" ]; then
    OS="linux"
else
    OS="darwin"
fi

# install wget if not installed
if ! [ -x "$(command -v wget)" ]; then
    if [ "$(uname)" = "Linux" ]; then
        apt-get update
        apt-get install -y wget
    else
        brew install wget
    fi
fi

# install curl if not installed
if ! [ -x "$(command -v curl)" ]; then
    if [ "$(uname)" = "Linux" ]; then
        apt-get install -y curl
    else
        brew install curl
    fi
fi

# install gcc and build essentials if not installed
if ! [ -x "$(command -v gcc)" ]; then
    if [ "$(uname)" = "Linux" ]; then
        apt-get install -y build-essential
    else
        brew install gcc
    fi
fi


# install golang version 1.18.10 if not already installed
if ! command -v go &> /dev/null
then
    echo "Installing golang version 1.18"
    wget https://golang.org/dl/go1.18.10.$OS-$ARCH.tar.gz
    tar -C /usr/local -xzf go1.18.10.$OS-$ARCH.tar.gz
    rm go1.18.10.$OS-$ARCH.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    #link go to /usr/local/bin/go so that it can be used from anywhere
    ln -s /usr/local/go/bin/go /usr/local/bin/go
fi

# install dasel if not already installed
if ! command -v dasel &> /dev/null
then
    echo "Installing dasel"
    URL="https://github.com/TomWright/dasel/releases/latest/download/dasel_${OS}_${ARCH}"
    wget $URL -O /usr/local/bin/dasel
    # set dasel permissions to executable by all users
    chmod a+x /usr/local/bin/dasel
fi

# install ignite cli if not already installed
if ! command -v ignite &> /dev/null
then
    echo "Installing ignite"
    IGVERSION=0.25.2
    URL="https://github.com/ignite/cli/releases/download/v${IGVERSION}/ignite_${IGVERSION}_${OS}_${ARCH}.tar.gz"
    wget $URL -O /tmp/ignite.tar.gz
    tar -xvf /tmp/ignite.tar.gz ignite
    mv ignite /usr/local/bin/ignite
fi

# print go version, if it fails then show error message with ====>
go version || (echo "====> go version failed, please check the logs above"; exit 1)

# print ignite version, if it fails then show error message with ====> 
ignite version || (echo "====> ignite version failed, please check the logs above"; exit 1)

# print dasel version, if it fails then show error message with ====> 
dasel --version || (echo "====> dasel version failed, please check the logs above"; exit 1)
