#!/bin/bash

set -e


cd  /ansible-tdd
./install



exec "$@"
