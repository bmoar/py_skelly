import logging
import logging
import sys

class LevelFilter():
    def __init__(self, level=None):
        """
            A filter that discards records of level <level>
        """
        self.level = level

    def filter(self, record):
        if self.level is None:
            allow = True
        else:
            allow = self.level not in record.levelname

        return allow


LOG_DICT = {
        'version': 1,
        'disable_existing_loggers': True,
        'filters': {
            'debug_filter': {
                '()': LevelFilter,
                'level': 'DEBUG',
                },
            },
        'formatters': {
            'simple': {
                'format': '[%(levelname)s] (%(filename)s) %(message)s'
                },
            'detailed': {
                'format': '%(asctime)s - [%(levelname)s] (%(filename)s:%(funcName)s:%(lineno)s) %(message)s'
                },
            },
        'handlers': {
            'info_console_hndl': {
                'class': 'logging.StreamHandler',
                'stream': 'ext://sys.stdout',
                'filters': ['debug_filter'],
                'formatter': 'detailed'
                },
            'error_console_hndl': {
                'class': 'logging.StreamHandler',
                'stream': 'ext://sys.stdout',
                'formatter': 'detailed',
                'filters': ['debug_filter'],
                'level': 'WARN'
                },
            'production_hndl': {
                'class': 'logging.FileHandler',
                'filename': '/var/tmp/skelly.log',
                'formatter': 'detailed',
                'filters': ['debug_filter'],
                'delay': True,
                },
            'development_hndl': {
                'class': 'logging.FileHandler',
                'filename': '/tmp/codeta-dev.log',
                'formatter': 'detailed',
                'filters': ['debug_filter'],
                'delay': True,
                },
            'testing_hndl': {
                'class': 'logging.FileHandler',
                'filename': '/tmp/codeta-test.log',
                'formatter': 'detailed',
                'filters': ['debug_filter'],
                'delay': True,
                },
            'debug_hndl': {
                'class': 'logging.FileHandler',
                'filename': '/tmp/codeta-debug.log',
                'formatter': 'detailed',
                'delay': True,
                },
            },
        'loggers': {
            'production': {
                'level': 'DEBUG',
                'handlers': ['production_hndl'],
                'propagate': False,
                },
            'development': {
                'level': 'DEBUG',
                'handlers': ['development_hndl'],
                'propagate': False,
                },
            'debug': {
                'level': 'DEBUG',
                'handlers': ['debug_hndl'],
                'propagate': False,
                },
            'testing': {
                'level': 'DEBUG',
                'handlers': ['testing_hndl'],
                'propagate': False,
                },
            },
        'root': {
            'level': 'INFO',
            'handlers': ['info_console_hndl', 'error_console_hndl'],
            },
        }
