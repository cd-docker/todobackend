########################
####   TEST STAGE   ####
########################
FROM alpine:3.13 AS test
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install operating system dependencies
RUN apk add --no-cache python3-dev py3-pip mariadb-dev gcc musl-dev linux-headers rsync
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install pipenv

# Copy application manifest
COPY Pipfile* /app/
WORKDIR /app

# Install application dependencies
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.local/share/virtualenvs \
    --mount=type=cache,target=/tmp/cache/build \
    pipenv install --dev --deploy && \
    pipenv clean && \
    rsync -avh --delete /root/.local/share/virtualenvs/ /tmp/cache/build/

# Copy virtual environment from temporary build cache
RUN --mount=type=cache,target=/tmp/cache/build \
    rsync -avh --delete /tmp/cache/build/ /root/.local/share/virtualenvs/

# Build production virtual environment
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/app/venv \
    --mount=type=cache,target=/tmp/cache/release \
    virtualenv /app/venv && \
    VIRTUAL_ENV=/app/venv pipenv install --deploy && \
    VIRTUAL_ENV=/app/venv pipenv clean && \
    rsync -avh --delete /app/venv/ /tmp/cache/release/

# Copy production virtual environment from temporary build cache
RUN --mount=type=cache,target=/tmp/cache/release \
    rsync -avh --delete /tmp/cache/release/ /app/venv/

# Test reports
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
WORKDIR /app/src
CMD ["python", "manage.py", "test", "--noinput"]

# Copy project
COPY . /app/

###########################
####   RELEASE STAGE   ####
###########################
FROM alpine:3.13 AS release
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-connector-c curl

# Create application user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copy application files
COPY --from=test --chown=app:app /app /app

# Public content
RUN mkdir -p /public && \
    chown -R app:app /public
VOLUME /public

# Set virtual environment path, working directory and application user
ENV PATH="/app/venv/bin:$PATH"
WORKDIR /app/src
USER app