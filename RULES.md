# Agon Health — Project Rules

## Infrastructure
- All AWS infrastructure must be written in **Terraform**
- No manual resource creation via the AWS Console (ClickOps)
- Terraform state stored remotely (S3 + DynamoDB locking)

## Deployment
- All deployments triggered via **GitHub Actions** workflows
- No manual deploys — everything goes through the pipeline
- Branches: `feature/*` → PR → `main` → deploy

## Environments
- `dev` — for testing, auto-deploys on merge to `main`
- `prod` — manual approval gate before deploy (when ready)

## iOS App
- SwiftUI + MVVM architecture
- iOS 17+ deployment target
- Code changes go through feature branches + PR review

## General
- Keep secrets in GitHub Secrets / AWS Secrets Manager — never in code
- Infrastructure and app code live in the same repo (monorepo)
- Terraform lives in an `infra/` directory at the root
