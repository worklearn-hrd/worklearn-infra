# 자주 쓰는 명령의 단축 이름. `make <이름>`으로 실행한다.

# .env의 값을 make 변수로 읽고, seed처럼 make가 띄우는 프로세스에도 환경변수로 넘긴다.
-include .env
export

# Windows에서는 호출한 터미널(PowerShell, Git Bash)에 상관없이 cmd.exe로 실행한다.
ifeq ($(OS),Windows_NT)
SHELL := cmd.exe
GRADLEW := ..\worklearn-api\gradlew.bat
else
GRADLEW := ../worklearn-api/gradlew
endif

.PHONY: up down logs psql seed

# 컨테이너를 띄우고 healthy가 될 때까지 기다린다.
up:
	docker compose up -d --wait

# 컨테이너를 내린다. 데이터(볼륨)는 남는다.
down:
	docker compose down

logs:
	docker compose logs -f

# postgres 컨테이너 안의 psql로 접속한다.
psql:
	docker compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# worklearn-api를 seed 프로파일로 실행해 테스트 데이터를 넣는다.
seed:
	$(GRADLEW) -p ../worklearn-api bootRun --args=--spring.profiles.active=seed
