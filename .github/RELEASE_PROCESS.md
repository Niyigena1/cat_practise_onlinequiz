# Phase 5: Release Process

This document explains how to create releases for the Online Quiz API.

## Semantic Versioning

We use **Semantic Versioning (SemVer)**: `MAJOR.MINOR.PATCH`

- **MAJOR** (v1.0.0): Breaking changes, incompatible API changes
- **MINOR** (v1.1.0): New features, backward compatible
- **PATCH** (v1.0.1): Bug fixes, small improvements

## Release Workflow

### Step 1: Create a Git Tag

Create a semantic version tag and push it to GitHub:

```bash
# Create a local tag
git tag -a v1.0.0 -m "Initial release of Online Quiz API"

# Push tag to GitHub
git push origin v1.0.0
```

### Step 2: Automated Release Process

When you push a tag matching `v*.*.*`, the release workflow automatically:

1. **Creates GitHub Release** with:
   - Auto-generated changelog from commits
   - Release notes
   - Docker image references

2. **Builds & Pushes Docker Image** to GHCR with:
   - Version tag: `ghcr.io/twahirwafab/class_quiz:v1.0.0`
   - Latest tag: `ghcr.io/twahirwafab/class_quiz:latest`
   - Multi-platform support (amd64, arm64)

3. **Generates SBOM** (Software Bill of Materials):
   - Lists all dependencies
   - Attached to GitHub Release

4. **Updates Kubernetes Deployment**:
   - Automatically updates `kubernetes/deployment.yaml` with new version
   - Commits and pushes to main branch

5. **Sends Slack Notification**:
   - Announces release in Slack
   - Links to release page and workflow

## Example Release Commands

### Release v1.0.0

```bash
# 1. Make sure all changes are committed
git status

# 2. Create the release tag
git tag -a v1.0.0 -m "Initial release - Online Quiz API v1.0.0

- Initial setup with Express server
- Quiz management API endpoints
- SQLite database integration
- Docker containerization
- Kubernetes deployment configs
- CI/CD pipeline with GitHub Actions
- Security scanning with Trivy
- Unit and integration tests"

# 3. Push the tag to GitHub
git push origin v1.0.0
```

### Release v1.1.0 (New Features)

```bash
# Create feature release
git tag -a v1.1.0 -m "Add admin dashboard and new quiz types"

# Push to GitHub
git push origin v1.1.0
```

### Release v1.0.1 (Bug Fix)

```bash
# Create patch release
git tag -a v1.0.1 -m "Fix health check endpoint and improve error handling"

# Push to GitHub
git push origin v1.0.1
```

## What Gets Created

### 🏷️ GitHub Release
- Visit: `https://github.com/TWAHIRWAFAB/Class_Quiz/releases/tag/v1.0.0`
- Contains:
  - Release notes with changelog
  - SBOM (Software Bill of Materials)
  - Download links

### 🐳 Docker Image
```bash
# Pull the released version
docker pull ghcr.io/twahirwafab/class_quiz:v1.0.0

# Or use latest tag
docker pull ghcr.io/twahirwafab/class_quiz:latest
```

### 📋 SBOM (Software Bill of Materials)
- Lists all npm dependencies
- Version information
- License details
- Attached to release for compliance

### ☸️ Kubernetes Deployment
- Automatically updated with new image version
- Committed to main branch
- Ready for deployment

## View Release Status

Go to: **https://github.com/TWAHIRWAFAB/Class_Quiz/actions**

Filter by workflow: **Release**

## Rollback to Previous Release

If you need to rollback to a previous version:

```bash
# List all releases
git tag -l

# Check out a previous release
git checkout v1.0.0

# Or update Kubernetes deployment to previous version
kubectl set image deployment/quiz-api quiz-api=ghcr.io/twahirwafab/class_quiz:v1.0.0 -n production
```

## Release Checklist

Before creating a release:

- [ ] All tests pass (`npm test`)
- [ ] Code passes linting (`npm run lint`)
- [ ] ESLint has no errors
- [ ] Changelog is updated (if manual documentation exists)
- [ ] Version number is appropriate (MAJOR.MINOR.PATCH)
- [ ] All commits are merged to main branch
- [ ] No uncommitted changes

## Troubleshooting

### Release workflow didn't trigger
- Check tag format: must match `v*.*.*` (e.g., v1.0.0, not 1.0.0)
- Verify tag was pushed: `git push origin v1.0.0`
- Check GitHub Actions status: https://github.com/TWAHIRWAFAB/Class_Quiz/actions

### Docker image not pushed
- Verify GITHUB_TOKEN has `packages: write` permission
- Check workflow has permission for `contents: read, packages: write`
- Review job logs for errors

### Slack notification not sent
- Ensure `SLACK_WEBHOOK_URL` secret is configured
- Verify webhook is valid and channel exists
- Check GitHub Actions secrets

## Next Steps

After release, you can:

1. **Deploy to production**:
   ```bash
   kubectl set image deployment/quiz-api quiz-api=ghcr.io/twahirwafab/class_quiz:v1.0.0 -n production
   ```

2. **Monitor deployment**:
   ```bash
   kubectl rollout status deployment/quiz-api -n production
   ```

3. **View logs**:
   ```bash
   kubectl logs -f deployment/quiz-api -n production
   ```
