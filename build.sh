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
            'ci = global_app.scripts.ci:main',
        ]
    },
    install_requires=[
        'nose',
        'coverage',
        'randomize',
        'factory-boy',
        'fake-factory',
        'cement'
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
    cat <<EOF > $SRC_DIR/$PROGRAM_NAME/scripts/ci.py
"""
    Entry point for CI scripts
"""

from cement.core import foundation
from global_app.conf.logger import init_logger

def create_app():
    """
        Configures an application according to env
    """
    app = foundation.CementApp('testing')

    app.setup()

    app.args.add_argument('-t', '--tests', action='store_true', dest='tests', help='Run nose tests')

    app.run()

    return app

def tests(app=None):
    import nose
    from nose.plugins.cover import Coverage

    nose.main(argv=['', '--randomize', '--with-coverage',
        '--cover-branches', '--cover-package=global_app'],
        addplugins=[Coverage()])

def main():
    # TODO: configure step

    log = init_logger(logger='debug')
    app = None

    try:
        app = create_app()
    except Exception as e:
        log.error('Failed to create app')
        log.debug('Exception: %s' % (e))
        if app:
            app.close()
    if app.pargs.tests:
        tests()
    else:
        log.info('Entry point hit')

    app.close()

if __name__ == '__main__':
    main()

EOF

}

_generate_logger(){
    cat << EOF > $SRC_DIR/$PROGRAM_NAME/conf/logger.py
class SyslogtagFilter():
    """ Injects a syslogtag into a log format """

    def __init__(self, syslogtag):
        self.syslogtag = syslogtag

    def filter(self, record):
        record.syslogtag = self.syslogtag
        return True

def init_logger(syslogtag='$PROGRAM_NAME', logger='debug'):
    import logging, logging.config

    loggers = {
            'version': 1,
            'disable_existing_loggers': True,
            'filters': {
                'syslogtag': {
                    '()': SyslogtagFilter,
                    'syslogtag': syslogtag,
                    },
                },
            'formatters': {
                'detailed': {
                    'format': '[%(syslogtag)s] [%(levelname)s] (%(filename)s:%(funcName)s:%(lineno)s) %(message)s'
                    },
                },
            'handlers': {
                'stderr': {
                    'class': 'logging.StreamHandler',
                    'stream': 'ext://sys.stderr',
                    'formatter': 'detailed',
                    'filters': ['syslogtag'],
                    },
                'syslog': {
                    'class': 'logging.handlers.SysLogHandler',
                    'address': '/dev/log',
                    'formatter': 'detailed',
                    'filters': ['syslogtag'],
                    },
                },
            'loggers': {
                'stderr': {
                    'level': 'INFO',
                    'handlers': ['stderr'],
                    'propagate': False,
                    },
                'debug': {
                    'level': 'DEBUG',
                    'handlers': ['stderr'],
                    'propagate': False,
                    },
                'prod': {
                    'level': 'INFO',
                    'handlers': ['syslog'],
                    'propagate': False,
                    },
                'prod_debug': {
                    'level': 'DEBUG',
                    'handlers': ['syslog'],
                    'propagate': False,
                    },
                },
            'root': {
                'level': 'INFO',
                'handlers': ['stderr'],
                },
            }
    logging.config.dictConfig(loggers)
    return logging.getLogger(logger)
EOF

}

_generate_tests() {

cat <<EOF > $SRC_DIR/$PROGRAM_NAME/tests/test_hello.py
import unittest
from $PROGRAM_NAME.scripts.ci import main

class BasicsTestCase(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_entry_point(self):
        pass

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
    _generate_logger
    _generate_tests
}

make_virtualenv() {

    # remove old virtualenv
    rm -rf $HOME/.virtualenvs/$PROGRAM_NAME

    # create new virtualenv
    mkdir -p $HOME/.virtualenvs/
    virtualenv -p /usr/bin/python3 $HOME/.virtualenvs/$PROGRAM_NAME

    # install app
    set +u
    source $HOME/.virtualenvs/$PROGRAM_NAME/bin/activate
    set -u
    python3 $SRC_DIR/setup.py develop

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
