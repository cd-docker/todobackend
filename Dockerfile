FROM alpine:3.13
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install operating system dependencies
RUN apk add --no-cache python3-dev py3-pip mariadb-dev gcc musl-dev
RUN pip install pipenv

# Copy project
COPY . /app/
WORKDIR /app

# Install application dependencies
RUN pipenv install --dev --deploy

# Test reports
VOLUME /reports

# Run commands in virtual environment
ENTRYPOINT ["pipenv", "run"]

# Run test commands by default
WORKDIR /app/src
CMD ["python", "manage.py", "test", "--noinput"]
