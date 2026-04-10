# Finance tracker app (MoneyFlow AI)

Full-stack personal finance tracker: **Flutter** client (`flutter-app/`), **NestJS** API with **Prisma** (`nest-backend/`), and **Docker Compose** for local infrastructure.

## Repository layout

| Path | Description |
|------|-------------|
| `flutter-app/` | Cross-platform app (mobile, desktop, web); Drift offline cache, Riverpod |
| `nest-backend/` | REST API, JWT auth, workspaces, expenses, budgets, AI insights, WhatsApp hooks |
| `docker-compose.yml` | Postgres and supporting services for local dev |
| `DESIGN.md` | UI / product design notes |

## Quick start

**Backend**

```bash
cd nest-backend
npm install
cp .env.example .env   # edit DATABASE_URL, secrets, etc.
npx prisma migrate dev
npm run start:dev
```

**Flutter**

```bash
cd flutter-app
flutter pub get
flutter run
```

Point the app at your API base URL (see `flutter-app/lib/core/api_config.dart` and env-specific overrides).

## Security

Do not commit real `.env` files. The root `.gitignore` excludes `.env` and common secrets.

## License

See [`LICENSE`](LICENSE).
