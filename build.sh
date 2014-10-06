#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="db-migration-script"
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_PATH="/usr/local/bin/"

clean() {
    rm -rf "$INSTALL_PATH/$PROGRAM_NAME"
}

make() {
    mkdir -p "$INSTALL_PATH/$PROGRAM_NAME"

    virtualenv "$INSTALL_PATH/$PROGRAM_NAME"
    cd $SRC_DIR
    $INSTALL_PATH/$PROGRAM_NAME/bin/python setup.py install

    fpm -s dir -t deb -n $PROGRAM_NAME -v 1.0 -d "python,python-dev" \
        $INSTALL_PATH/$PROGRAM_NAME=$INSTALL_PATH
}

main() {
    clean
    make
}

main
