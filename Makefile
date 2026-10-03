.PHONY: up down status logs backup restore update check test

up:
	docker compose up -d --build
down:
	docker compose down
status:
	docker compose ps
logs:
	docker compose logs -f --tail=100
backup:
	./scripts/backup.sh
restore:
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=backups/file.dump" && exit 2)
	./scripts/restore.sh "$(FILE)"
update:
	./scripts/update.sh
check:
	./scripts/check.sh
test:
	./tests/validate.sh
