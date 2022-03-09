#!/bin/bash

tar --exclude=.DS_Store \
    --exclude=package.sh \
    -zcvf system_setup.tar.gz *

