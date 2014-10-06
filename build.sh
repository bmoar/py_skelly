#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="py_skelly"
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_PATH="/usr/local/bin/"

clean() {
    rm -rf $SRC_DIR/build
    rm -rf $SRC_DIR/dist
    rm -rf $SRC_DIR/*.egg-info
    rm -rf $SRC_DIR/*.deb
}

make() {
    mkdir -p "$INSTALL_PATH/$PROGRAM_NAME"

    virtualenv "$INSTALL_PATH/$PROGRAM_NAME"
    cd $SRC_DIR
    $INSTALL_PATH/$PROGRAM_NAME/bin/python setup.py install

    fpm -s dir -t deb -n $PROGRAM_NAME -v 1.0 -d "python,python-dev" \
        $INSTALL_PATH/$PROGRAM_NAME=$INSTALL_PATH
}

usage() {
    echo "build.sh < clean | make >"
    exit 1
}

main() {
    case $1 in
        clean)
            clean
            ;;
        make)
            make
            ;;
        *)
            usage
            ;;
    esac
}

if [ $# -ne 1 ]; then
    usage
fi

main $1
