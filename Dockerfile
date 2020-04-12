# syntax = docker/dockerfile:experimental
########################
####   TEST STAGE   ####
########################
FROM alpine:3.10 as test
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install build dependencies
RUN apk add --no-cache gcc python3-dev musl-dev linux-headers mariadb-dev rsync
RUN --mount=type=cache,target=/root/.cache \
    pip3 install pipenv

# Create skeleton virtual environment
WORKDIR /app
RUN pipenv install

# Copy Pipfiles
COPY Pipfile* /app/

# Build and install application dependencies
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.local/share/virtualenvs \
    --mount=type=cache,target=/build \
    pipenv install --dev --deploy && \
    pipenv clean && \
    rsync -avh --delete $(pipenv --venv)/ /build/

# Copy virtual environment from temporary build cache
RUN --mount=type=cache,target=/build \
    rsync -avh --delete /build/ $(pipenv --venv)/ 

# Build production virtual environment
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/app/venv \
    --mount=type=cache,target=/build \
    virtualenv /app/venv && \
    VIRTUAL_ENV=/app/venv pipenv install --deploy && \
    VIRTUAL_ENV=/app/venv pipenv clean && \
    rsync -avh --delete /app/venv/ /build/

# Copy production virtual environment from temporary build cache
RUN --mount=type=cache,target=/build \
    rsync -avh --delete /build/ /app/venv/

# Test reports
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
WORKDIR /app/src
CMD ["python", "manage.py", "test", "--noinput"]

# Copy application source
COPY tests /app/tests
COPY src /app/src

###########################
####   RELEASE STAGE   ####
###########################
FROM alpine:3.10 as release
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-connector-c

# Create application user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copy application files
COPY --from=test --chown=app:app /app /app

# Set virtual environment path, working directory and application user
ENV PATH="/app/venv/bin:$PATH"
WORKDIR /app/src
USER app
