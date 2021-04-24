test:
	docker-compose pull db
	docker-compose build --pull test
	docker-compose up --abort-on-container-exit --force-recreate test
	docker-compose up --abort-on-container-exit --force-recreate test-integration

release:
	docker-compose build release
	docker-compose up --abort-on-container-exit --force-recreate acceptance

clean:
	docker-compose down -v

# Make settings
.PHONY: test release clean
.ONESHELL:
.SILENT:
SHELL=/bin/bash
.SHELLFLAGS = -ceo pipefail