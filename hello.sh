#!/bin/sh
################################################################################
## hello.sh -- sample script
##
## - Author: 2025, tomyama
## - A test script for creating directories that serves as a template for the script collection.
##
## BSD 2-Clause License:
## Copyright (c) 2025, tomyama
## All rights reserved.
################################################################################

if [ "$1" = '-h' -o "$1" = '--help' ]; then
    echo "Usage: hello.sh [OPTIONS]"
    echo "This is a sample script."
    echo "A test script for creating directories that serves as a template for the script collection."
    echo ""
    echo "OPTIONS"
    echo "  -h, --help     display this help and exit"
    echo "  -v, --version  output version information and exit"
    exit 0
elif [ "$1" = '-v' -o "$1" = '--version' ]; then
    echo "$0 v1.0"
    exit 0
fi

echo "hello, world!"
