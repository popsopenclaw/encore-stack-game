.PHONY: up down logs ps build test analyze

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

ps:
	docker compose ps

build:
	dotnet build backend/Encore.Api/Encore.Api.csproj

test:
	dotnet test backend/Encore.Api.Tests/Encore.Api.Tests.csproj

analyze:
	cd frontend && flutter analyze
