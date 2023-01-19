#!/bin/sh
set -ex
# Build the release binary using ignite and extract the resulting binary from archive.

ignite chain build --release

tar -xvf ./release/dominion_*_*.tar.gz 

cp dominiond /usr/local/bin/
chmod a+x /usr/local/bin/dominiond



