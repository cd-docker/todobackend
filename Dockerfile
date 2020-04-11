# syntax = docker/dockerfile:experimental
######################
###   TEST STAGE   ###
######################
FROM alpine:3.10 as test
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install utilities
RUN apk add --no-cache bash git

# Install build dependencies
RUN apk add --no-cache gcc python3-dev musl-dev linux-headers mariadb-dev
RUN --mount=type=cache,target=/root/.cache/pip pip3 install pipenv

# Copy Pipfiles
COPY Pipfile* /app/
WORKDIR /app

# Build and install requirements
RUN --mount=type=cache,target=/root/.cache/pipenv pipenv install --dev --deploy

# Build production virtual environment
RUN --mount=type=cache,target=/root/.cache/pipenv virtualenv venv && \
    VIRTUAL_ENV=venv pipenv sync

# Copy application source
COPY /src /app

# Volume for test output
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
CMD ["python3", "manage.py", "test", "--noinput"]

#######################
###  RELEASE STAGE  ###
#######################
FROM alpine:3.10
LABEL application=todobackend

# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-connector-c

# Create application user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copy application source and virtual environment
COPY --from=test --chown=app:app /app /app

# Create public volume
# RUN mkdir /public
# RUN chown app:app /public
# VOLUME /public

# Set virtual environment path, working directory and application user
ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
WORKDIR /app
USER app