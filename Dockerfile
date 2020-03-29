FROM alpine:3.10
LABEL application=todobackend

# Environment settings
ENV LANG=C.UTF-8

# Install utilities
RUN apk add --no-cache bash git

# Install build dependencies
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install pipenv

# Copy Pipfiles
COPY Pipfile* /app/
WORKDIR /app

# Build and install requirements
RUN pipenv install --dev --deploy

# Build production virtual environment
RUN virtualenv venv && \
    VIRTUAL_ENV=venv pipenv sync

# Copy application source
COPY /src /app

# Volume for test output
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
CMD ["python3", "manage.py", "test", "--noinput"]
