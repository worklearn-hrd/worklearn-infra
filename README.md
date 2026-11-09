# worklearn-infra

워크런(WorkLearn)의 인프라 저장소. 로컬 개발 환경(Docker Compose), AWS 기반 인프라(Terraform), GitHub Actions 재사용 워크플로, 모니터링 설정을 둔다.

## 로컬 개발 환경

PostgreSQL 16(pgvector 포함)과 Redis 7을 Docker Compose로 띄운다. 이 저장소는 `worklearn-api`, `worklearn-web`과 같은 폴더 아래에 나란히 있어야 한다.

### 준비물

- Docker Desktop (Compose v2 포함)
- GNU Make — Windows는 `winget install ezwinports.make` 후 터미널을 새로 연다. macOS·Linux는 기본으로 있다.

### 처음 실행

```sh
cp .env.example .env    # 그다음 .env의 POSTGRES_PASSWORD를 채운다
make up                 # postgres·redis를 띄우고 healthy가 될 때까지 기다린다
make seed               # 테스트 데이터를 넣는다
```

`make seed`는 `worklearn-api`의 `seed` 프로파일이 만들어진 뒤부터 동작한다.

### 명령

| 명령 | 하는 일 |
| --- | --- |
| `make up` | 컨테이너를 띄우고 healthy가 될 때까지 기다린다 |
| `make down` | 컨테이너를 내린다. 데이터는 남는다 |
| `make logs` | 컨테이너 로그를 따라 본다 (Ctrl+C로 종료) |
| `make psql` | postgres 컨테이너 안의 `psql`로 접속한다 |
| `make seed` | `../worklearn-api`를 `seed` 프로파일로 실행해 테스트 데이터를 넣는다 |

데이터까지 지우고 처음부터 시작하려면 `docker compose down -v`를 쓴다.

### 접속 정보

| 서비스 | 호스트에서 | 값의 출처 |
| --- | --- | --- |
| postgres | `localhost:${POSTGRES_PORT}` (기본 5432) | DB·사용자·비밀번호는 `.env` |
| redis | `localhost:${REDIS_PORT}` (기본 6379) | 비밀번호 없음 |

포트는 `127.0.0.1`에만 열린다. 이미 쓰는 포트와 겹치면 `.env`의 `POSTGRES_PORT`·`REDIS_PORT`를 바꾼다.

## CI — 재사용 워크플로

코드 레포는 자기 `.github/workflows/ci.yml`에서 이 저장소의 워크플로를 호출한다. 빌드 절차를 고칠 때는 여기 한 곳만 고친다.

| 워크플로 | 쓰는 레포 | 하는 일 |
| --- | --- | --- |
| `gradle-ci.yml` | `worklearn-api`, `worklearn-batch` | JDK 21(temurin) → `./gradlew build`(Testcontainers 테스트 포함). 실패하면 테스트 리포트를 7일 보관 |
| `next-ci.yml` | `worklearn-web` | `.nvmrc`의 Node → `npm ci` → `next typegen` + `tsc --noEmit` → `npm run lint` → `npm run build` |

### 호출 예시

`worklearn-api`·`worklearn-batch`의 `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: worklearn-hrd/worklearn-infra/.github/workflows/gradle-ci.yml@main
```

`worklearn-web`은 마지막 줄만 `next-ci.yml@main`으로 바꾼다.

### 호출하는 레포가 갖출 것

- Gradle: `gradlew`에 실행 권한이 있어야 한다. Windows에서 만든 프로젝트는 권한이 빠져 있으므로 `git update-index --chmod=+x gradlew` 후 커밋한다.
- Next: `.nvmrc`, `package-lock.json`, `package.json`의 `lint`·`build` 스크립트, TypeScript.

브랜치 보호에 넣을 필수 체크 이름은 `ci / gradle`(api·batch)과 `ci / next`(web)다.

## 디렉토리

| 경로 | 내용 |
| --- | --- |
| `.github/workflows/` | 다른 레포가 호출하는 CI 재사용 워크플로 |
| `docker-compose.yml` | 로컬 개발 환경 |
| `Makefile` | 자주 쓰는 명령의 단축 이름 |
| `load/` | k6 부하 테스트 스크립트 (2단계부터) |
