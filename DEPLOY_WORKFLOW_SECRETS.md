# GitHub Actions VM Deploy Secrets

For `.github/workflows/deploy-vm.yml`, set these repository secrets:

- `VM_HOST`
- `VM_SSH_USER`
- `VM_SSH_PORT`
- `VM_SSH_KEY` (private key text)
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `JWT_ISSUER`
- `JWT_AUDIENCE`
- `JWT_SIGNING_KEY`
- `GITHUB_CLIENT_ID`
- `GITHUB_CLIENT_SECRET`
- `GITHUB_REDIRECT_URI`
- `BACKEND_PORT`

## How to run

1. Go to **Actions** tab in GitHub repo.
2. Select **deploy-vm** workflow.
3. Click **Run workflow**.
4. Pick `ref` and `mode` (`prod` recommended).
