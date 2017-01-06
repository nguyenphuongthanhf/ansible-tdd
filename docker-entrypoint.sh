#!/bin/bash

set -e


cd  /ansible-tdd
./install
rm /usr/bin/ansible-tdd -rf
rm /usr/bin/atdd -rf
ln -s /ansible-tdd/ansible-tdd /usr/bin/ansible-tdd
ln -s /ansible-tdd/ansible-tdd /usr/bin/atdd


exec "$@"
