#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="py_skelly"
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_PATH="/usr/local/bin/"
SYSTEM_DEPS="python,python-dev"

dirs=()
pydirs=()

_clean_dirs() {
    for dir in "${dirs[@]}"; do
        rm -rf $SRC_DIR/$dir
    done

    for dir in "${pydirs[@]}"; do
        rm -rf $SRC_DIR/$dir
    done
}

_clean_py() {
    rm -rf $SRC_DIR/setup.py
    rm -rf $SRC_DIR/*.egg-info
}

_generate_dirs() {
    for dir in "${dirs[@]}"; do
        mkdir -p $SRC_DIR/$dir
    done

    # python module dirs need an init
    for dir in "${pydirs[@]}"; do
        mkdir -p $SRC_DIR/$dir
        touch $SRC_DIR/$dir/__init__.py
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
    ],
    tests_require=['nose'],
    test_suite='nose.collector',
    classifiers=[
        'Private :: Do Not Upload'
    ],
    dependency_links=[]
)
EOF
}

_generate_entrypoint() {
    touch $SRC_DIR/$PROGRAM_NAME/scripts/__init__.py
    cat <<EOF > $SRC_DIR/$PROGRAM_NAME/scripts/hello.py

def main():
    print 'hello world!'

if __name__ == '__main__':
    main()
EOF

}

_setup() {
    dirs=(
        "docs"
    )
    pydirs=(
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
    _generate_entrypoint
}

make_virtualenv() {

    # remove old virtualenv
    rm -rf $HOME/.virtualenvs/$PROGRAM_NAME

    # create new virtualenv
    mkdir -p $HOME/.virtualenvs/
    virtualenv $HOME/.virtualenvs/$PROGRAM_NAME

    # install app
    set +u
    source $HOME/.virtualenvs/$PROGRAM_NAME/bin/activate
    set -u
    python $SRC_DIR/setup.py develop

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
                _setup "${args[i]}"
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
                _setup "${args[i]}"
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
