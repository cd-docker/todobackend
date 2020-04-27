.PHONY: test release clean version publish login logout

export DOCKER_BUILDKIT ?= 1
export COMPOSE_DOCKER_CLI_BUILD ?= 1
export APP_VERSION ?= $(shell git rev-parse --short HEAD)

version:
	echo $(APP_VERSION)

test:
	${INFO} "Pulling latest images..."
	docker-compose pull
	${INFO} "Building images..."
	docker-compose build --pull release
	docker-compose build
	${INFO} "Running tests..."
	docker-compose up test
	${INFO} "Collecting test reports..."
	mkdir -p build
	test=$$(docker-compose ps -q test)
	docker cp $$test:/reports build
	${INFO} "Checking test result..."
	result=$$(docker inspect -f "{{ .State.ExitCode }}" $$test)
	if [[ $$result -ne 0 ]]
		then ${ERROR} "Test failure"
	fi
	${INFO} "Test stage complete"

release:
	${INFO} "Running database migrations..."
	docker-compose up --abort-on-container-exit migrate
	${INFO} "Collecting static files..."
	docker-compose run app python manage.py collectstatic --no-input
	${INFO} "Running acceptance tests..."
	docker-compose up acceptance
	${INFO} "Collecting test reports..."
	acceptance=$$(docker-compose ps -q acceptance)
	docker cp $$acceptance:/reports/acceptance.xml build/reports/acceptance.xml
	${INFO} "Checking test result..."
	result=$$(docker inspect -f "{{ .State.ExitCode }}" $$acceptance)
	if [[ $$result -ne 0 ]]
		then ${ERROR} "Test failure"
	fi
	${INFO} "Release stage complete"
	${INFO} "App running at http://$$(docker-compose port app 8000 | sed s/0.0.0.0/localhost/g)"

login:
	${INFO} "Logging into Docker Hub..."
	cat $$DOCKER_PASSWORD | docker login --username $$DOCKER_USER --password-stdin
	${INFO} "Login stage complete"

publish:
	${INFO} "Publishing images..."
	docker-compose push
	${INFO} "Publish stage complete"

logout:
	${INFO} "Logging out..."
	docker logout
	${INFO} "Logout stage complete"

clean:
	${INFO} "Cleaning environment..."
	docker-compose down -v
	docker images -q -f dangling=true -f label=application=todofrontend | xargs -I ARGS docker rmi -f --no-prune ARGS
	rm -rf build
	${INFO} "Clean stage complete"

# Recommended settings
.ONESHELL:
.SILENT:
SHELL=/bin/bash
.SHELLFLAGS = -ceo pipefail

# Cosmetics
YELLOW := "\e[1;33m"
RED := "\e[1;31m"
NC := "\e[0m"
INFO := bash -c 'printf $(YELLOW); echo "=> $$0"; printf $(NC)'
ERROR := bash -c 'printf $(RED); echo "ERROR: $$0"; printf $(NC); exit 1'