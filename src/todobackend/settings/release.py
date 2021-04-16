from todobackend.settings import *
import os

# Debug
if os.environ.get('DEBUG', 'false').lower() in ['true', 'yes', '1']:
    DEBUG = True
else:
    DEBUG = False

# Must be explicitly specified when Debug is disabled
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

# Set secret key
SECRET_KEY = os.environ.get('SECRET_KEY', SECRET_KEY)

# Database settings
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

# Static content settings
STATIC_ROOT = os.environ.get('STATIC_ROOT', '/public/static')
MEDIA_ROOT = os.environ.get('MEDIA_ROOT', '/public/media')
