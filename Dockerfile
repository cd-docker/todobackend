FROM alpine:3.10
LABEL application=todobackend

# Language settings
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install build dependencies
RUN apk add --no-cache gcc python3-dev musl-dev linux-headers mariadb-dev
RUN pip3 install pipenv

# Copy Pipfiles
COPY Pipfile* /app/
WORKDIR /app

# Build and install application dependencies
RUN pipenv install --dev --deploy

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