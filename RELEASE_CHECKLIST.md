# RELEASE_CHECKLIST

## Preflight
- [ ] `./scripts/ci-local.sh` passes
- [ ] `./scripts/smoke-local.sh` passes
- [ ] `.env` has required secrets (`JWT_SIGNING_KEY`, GitHub OAuth vars)
- [ ] DB migration image builds successfully

## Deploy
- [ ] Run deploy script to VM (`scripts/deploy-vm.sh`)
- [ ] Confirm `migrate` service completed successfully
- [ ] Confirm API health endpoint responds (`/health`)
- [ ] Confirm realtime hub endpoint is reachable (`/hubs/lobby/negotiate`)

## Post-deploy verification
- [ ] Login works
- [ ] Create lobby / join lobby works
- [ ] Realtime lobby updates observed between two clients
- [ ] Start game + roll + move + score/events work
- [ ] Request logs include method/path/status/duration + correlation id (`X-Correlation-Id`)

## Backup / rollback safety
- [ ] Run backup script before major release (`scripts/backup-vm.sh`)
- [ ] Keep previous image tags/commit available for rollback
- [ ] Rollback command documented and tested on non-prod VM

## Rollback quick procedure
1. Checkout previous known-good commit on VM copy
2. Re-run deploy with that commit
3. Confirm `/health` and critical flows
4. Restore DB backup only if schema/data mismatch requires it
