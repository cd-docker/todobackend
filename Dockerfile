# syntax = docker/dockerfile:experimental
FROM alpine:3.10
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