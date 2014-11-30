#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="py_skelly"
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_PATH="/usr/local/bin/"
SYSTEM_DEPS="python,python-dev"

dirs=()

_clean_dirs() {
    for dir in "${dirs[@]}"; do
        rm -rf $dir
    done
}

_generate_dirs() {
    for dir in "${dirs[@]}"; do
        mkdir -p $dir
    done
}

_setup_dirs() {
    dirs=(
        "docs"
        "$1"
        "$1/scripts"
        "$1/tests"
        "$1/conf"
    )
}

clean() {
    _clean_dirs
}

generate() {
    _generate_dirs
}

usage() {
cat <<EOF
build.sh option [arg]
-b | --bootstrap - install all system dependencies needed to run a basic app
-g <name> | --generate <name> - generate a python module template called name
-c <name> | --clean <name> - remove generated python template called name
-v | --virtualenv - create a virtualenv in ~/.virtualenvs and install all the requirements into it
EOF

exit 1
}

main() {
    options=$@
    args=($options)
    i=0

    if [ $# -eq 0 ]; then
        usage
    fi

    for arg in $options; do
        i=$(( $i + 1 ))

        case $arg in
            -b|--bootstrap|bootstrap)
                bootstrap
                break
                ;;
            -g|--generate|generate)
                _setup_dirs "${args[i]}"
                generate
                break
                ;;
            -c|--clean|clean)
                _setup_dirs "${args[i]}"
                clean
                break
                ;;
            -v|--virtualenv|virtualenv)
                make_virtualenv
                break
                ;;
            *)
                usage
                break
                ;;
        esac
    done

}

main $@
