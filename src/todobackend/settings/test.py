from .base import *
import os

# Installed Apps
INSTALLED_APPS += ('django_nose', )
TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'
TEST_OUTPUT_DIR = os.environ.get('TEST_OUTPUT_DIR', '.')
NOSE_ARGS = [
    '--verbosity=2',                                        # verbose output
    '--nologcapture',                                       # don't output log capture
    '--with-coverage',                                      # activate coverage report
    '--cover-package=todo',                                 # coverage reports will apply to these packages
    '--with-spec',                                          # spec style tests
    '--spec-color',                                         # make them pretty
    '--with-xunit',                                         # enable xunit plugin
    f'--xunit-file={TEST_OUTPUT_DIR}/nosetests.xml',        # xunit test output
    '--cover-xml',                                          # produce XML coverage info
    f'--cover-xml-file={TEST_OUTPUT_DIR}/coverage.xml',     # XML coverage output
]

# Database
# https://docs.djangoproject.com/en/3.0/ref/databases/#mysql-notes
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('MYSQL_DATABASE','todobackend'),
        'USER': os.environ.get('MYSQL_USER','todo'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD','password'),
        'HOST': os.environ.get('MYSQL_HOST','localhost'),
        'PORT': os.environ.get('MYSQL_PORT','3306'),
    }
}