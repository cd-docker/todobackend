.PHONY: test release clean

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

test:
	docker-compose build --pull release
	docker-compose build
	docker-compose up --abort-on-container-exit test

release:
	docker-compose up --abort-on-container-exit migrate
	docker-compose run app python manage.py collectstatic --no-input
	docker-compose up --abort-on-container-exit acceptance

clean:
	docker-compose down -v