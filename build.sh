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

_clean_py() {
    rm -rf $SRC_DIR/setup.py
}

_generate_dirs() {
    for dir in "${dirs[@]}"; do
        mkdir -p $dir
    done
}

_generate_setuppy() {
    cat <<EOF > $SRC_DIR/setup.py
from setuptools import setup, find_packages

setup(
    name='$PROGRAM_NAME',
    version='0.0',
    packages=find_packages(),
    package_data={"conf": "$PROGRAM_NAME/conf/*"},
    zip_safe=False,
    entry_points={
        'console_scripts': [
            'hello = $PROGRAM_NAME.scripts.hello:main'
        ]
    },
    install_requires=[
        'nose',
        'coverage',
        'randomize',
        'factory-boy',
        'fake-factory',
    ])
    tests_require=['nose'],
    test_suite='nose.collector',
    classifiers=[
        'Private :: Do Not Upload'
    ],
    dependency_links=[]
)
EOF
}

_setup() {
    dirs=(
        "docs"
        "$1"
        "$1/scripts"
        "$1/tests"
        "$1/conf"
    )

    PROGRAM_NAME=$1
}

clean() {
    _clean_dirs
    _clean_py
}

generate() {
    _generate_dirs
    _generate_setuppy
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
                _setup "${args[i]}"
                generate
                break
                ;;
            -c|--clean|clean)
                _setup "${args[i]}"
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
