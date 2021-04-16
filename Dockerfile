FROM alpine:3.13
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install operating system dependencies
RUN apk add --no-cache python3-dev py3-pip mariadb-dev gcc musl-dev rsync
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

# Test reports
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
WORKDIR /app/src
CMD ["python", "manage.py", "test", "--noinput"]

# Copy project
COPY . /app/
