#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="py_skelly"
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_PATH="/usr/local/bin/"
SYSTEM_DEPS="python,python-dev"

dirs=()
pydirs=()

_generate_build_script() {
    cat <<EOF > $SRC_DIR/$PROGRAM_NAME/build.sh
#!/usr/bin/env bash

set -eu
set -o pipefail

PROGRAM_NAME="$PROGRAM_NAME"
EOF
    cat $SRC_DIR/build_template >> $SRC_DIR/$PROGRAM_NAME/build.sh
    chmod +x $SRC_DIR/$PROGRAM_NAME/build.sh
}

_generate_dirs() {
    mkdir -p $SRC_DIR/$PROGRAM_NAME

    for dir in "${dirs[@]}"; do
        mkdir -p $SRC_DIR/$PROGRAM_NAME/$dir
    done

    # python module dirs need an init
    for dir in "${pydirs[@]}"; do
        mkdir -p $SRC_DIR/$PROGRAM_NAME/$dir
        touch $SRC_DIR/$PROGRAM_NAME/$dir/__init__.py
    done
}

_generate_entrypoint_symlink() {
    cd $SRC_DIR/$PROGRAM_NAME
    ln -s $PROGRAM_NAME/cli/entry_point.py entry_point.py
}

_generate_setuppy() {
    cat <<EOF > $SRC_DIR/$PROGRAM_NAME/setup.py
from setuptools import setup, find_packages

setup(
    name='$PROGRAM_NAME',
    version='0.0',
    packages=find_packages(),
    package_data={"conf": "$PROGRAM_NAME/conf/*"},
    zip_safe=False,
    entry_points={
        'console_scripts': [
            'ci = $PROGRAM_NAME.cli.entry_point:main',
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
    PROGRAM_APPNAME=$PROGRAM_NAME
    PROGRAM_APPNAME+="App"
    cat <<EOF > $SRC_DIR/$PROGRAM_NAME/$PROGRAM_NAME/cli/entry_point.py
#!/usr/bin/env python

"""
    Entry point for CLI
"""

from cement.core import foundation
from cement.core.exc import CaughtSignal, FrameworkError
from cement.core.controller import CementBaseController, expose

from $PROGRAM_NAME.core.conf.logger import init_logger

class BaseController(CementBaseController):
    class Meta:
        label = 'base'
        description = '$PROGRAM_NAME - a python cli skeleton'
        arguments = [
            (['-n', '--name'], dict(help='an example arg')),
        ]

    @expose(hide=True)
    def default(self):
        self.app.log.info('hello world, this is the default function')

    @expose(help='run nosetest unit tests')
    def tests(self):
        """Run the unit tests and report coverage"""
        import nose
        from nose.plugins.cover import Coverage
        # Don't mess with argv in nose.main(). It requires the first argument in the list to be empty
        # string. The other two start coverage and set the package to this app.
        nose.main(argv=['', '--with-coverage', '--cover-branches', '--cover-package=$PROGRAM_NAME'], addplugins=[Coverage()])

class $PROGRAM_APPNAME(foundation.CementApp):
    class Meta:
        label = '$PROGRAM_NAME'
        base_controller = BaseController

def main():
    rc = 0
    log = init_logger(logger_type='debug')
    app = $PROGRAM_APPNAME()

    try:
        app.setup()
        app.log = log
        app.run()
    except CaughtSignal as e:
        app.log.error('caught signal %s' % (e))
        rc = 1
    except FrameworkError as e:
        app.log.error('framework error %s' % (e))
        rc = 2
    except Exception as e:
        app.log.error('exception %s' % (e))
        rc = 1

    finally:
        app.close(rc)

if __name__ == '__main__':
    main()

EOF

}

_generate_logger(){
    cat << EOF > $SRC_DIR/$PROGRAM_NAME/$PROGRAM_NAME/core/conf/logger.py
class SyslogtagFilter():
    """ Injects a syslogtag into a log format """

    def __init__(self, syslogtag):
        self.syslogtag = syslogtag

    def filter(self, record):
        record.syslogtag = self.syslogtag
        return True

def init_logger(syslogtag='$PROGRAM_NAME', logger_type='debug'):
    import logging, logging.config

    logger_types = {
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
    logging.config.dictConfig(logger_types)
    return logging.getLogger(logger_type)
EOF

}

_generate_tests() {

cat <<EOF > $SRC_DIR/$PROGRAM_NAME/$PROGRAM_NAME/core/tests/test_hello.py
import unittest
from $PROGRAM_NAME.core.conf.logger import init_logger

class BasicsTestCase(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_logger(self):
        logger = init_logger()
        logger.info('test')
        assert logger

EOF

}

_setup() {

    PROGRAM_NAME=$1

    dirs=(
        "docs"
    )
    pydirs=(
        "$PROGRAM_NAME"
        "$PROGRAM_NAME/core"
        "$PROGRAM_NAME/core/tests"
        "$PROGRAM_NAME/core/conf"
        "$PROGRAM_NAME/cli"
    )

}

clean() {
    rm -rf $SRC_DIR/$PROGRAM_NAME
}

generate() {
    _generate_dirs
    _generate_setuppy
    _generate_entrypoint
    _generate_logger
    _generate_tests
    _generate_build_script
    _generate_entrypoint_symlink
}

usage() {
cat <<EOF
build.sh option [arg]
-g <name> | --generate <name> - generate a python module template called name
-c <name> | --clean <name> - remove generated python template called name
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
            *)
                usage
                break
                ;;
        esac
    done

}

main $@
