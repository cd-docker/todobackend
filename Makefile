-include .env

.PHONY: all build test release clean version publish login logout

DOCKER_BUILDKIT ?= 1
COMPOSE_DOCKER_CLI_BUILD ?= 1
GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git tag | grep ^[[:digit:]]*.[[:digit:]]*.[[:digit:]]*$$ || printf '0.0.0')
PR_COMMIT := $(shell git show --no-patch --format="%H" HEAD^2 2>/dev/null || echo $(GIT_COMMIT))
export

all: clean build test release

version:
	$(call version)
	${INFO} "Git commit: $(GIT_COMMIT)"
	${INFO} "Pull request commit: $(PR_COMMIT)"
	${INFO} "Current version: $(GIT_TAG)"
	${INFO} "Next version: $$version"

build:
	${INFO} "Pulling latest images..."
	docker-compose pull
	${INFO} "Building images..."
	docker-compose build --pull release
	docker-compose build
	${INFO} "Build stage complete"

test:
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

tag:
	$(call version)
	${INFO} "Pulling image $(PR_COMMIT)..."
	docker pull continuousdeliverydocker/todobackend:$(PR_COMMIT)
	${INFO} "Tagging image $(PR_COMMIT) with $$version and latest tags..."
	docker tag continuousdeliverydocker/todobackend:$(PR_COMMIT) continuousdeliverydocker/todobackend:$$version
	docker tag continuousdeliverydocker/todobackend:$(PR_COMMIT) continuousdeliverydocker/todobackend:latest
	docker push continuousdeliverydocker/todobackend:$$version
	docker push continuousdeliverydocker/todobackend:latest
	hub release create -m "$$version" $$version
	${INFO} "Tag stage complete"

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

# Functions
define version
	current_versions=( $$(printf "$(GIT_TAG)" | sort -V) )
	current_version=$${current_versions[@]:(-1)}
	target_version=$(file <VERSION)
	parts=( $${current_version//./ } )
	((parts[2]++))
	new_version="$${parts[0]}.$${parts[1]}.$${parts[2]}"
	versions=( $$(printf "$$target_version\n$$new_version" | sort -V) )
	version=$${versions[@]:(-1)}
endef