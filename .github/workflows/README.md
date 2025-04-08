# GitHub Actions CI/CD Setup

This project uses GitHub Actions for continuous integration and deployment.

## Required Secrets

You need to set up the following secrets in your GitHub repository:

### For CI workflow:

- No additional secrets required as we use SQLite3 for testing.

### For CD workflow:

1. `KAMAL_REGISTRY_USERNAME`: Docker registry username
2. `KAMAL_REGISTRY_PASSWORD`: Docker registry access token
3. `RAILS_MASTER_KEY`: Your Rails master key from `config/master.key`

## Additional Deployment Configuration

The deployment relies on Kamal and assumes you have already set up your server with:

1. SSH access configured
2. Docker installed
3. Proper firewall settings

## How the CI/CD Pipeline Works

1. **CI Process**:
   - Runs on every pull request and push to main
   - Performs security scans (Brakeman for Ruby, importmap audit for JS)
   - Lints code with Rubocop
   - Runs RSpec tests with SQLite3 as the database

2. **CD Process**:
   - Only runs on push to main branch
   - Waits for tests to pass
   - Builds the Docker image with the production Dockerfile
   - Pushes the image to Docker Hub using registry credentials from secrets
   - Deploys using Kamal

## Manual Deployment

To manually trigger a deployment, go to the Actions tab in your GitHub repository and select the "Deploy" workflow, then click "Run workflow".

## Local Testing

To test the CI workflow locally before pushing, you can use [act](https://github.com/nektos/act), a tool for running GitHub Actions locally.

# Version Management

This project follows [Semantic Versioning 2.0.0](https://semver.org/). Version numbers follow the pattern: MAJOR.MINOR.PATCH

## Version Bump Rules

When creating a Pull Request, use one of these labels to indicate the type of change:

### 1. `breaking-change`
- Use when making incompatible API changes
- Examples:
  - Removing or renaming public API methods
  - Changing method signatures
  - Breaking changes in behavior
- Increments MAJOR version (X.y.z)

### 2. `feature`
- Use when adding backwards-compatible functionality
- Examples:
  - New features that don't break existing APIs
  - Deprecating existing functionality
  - Adding new optional parameters
- Increments MINOR version (x.Y.z)

### 3. No Label (Default: Patch)
- Use for backwards-compatible bug fixes
- Examples:
  - Bug fixes that don't change the public API
  - Internal refactoring that maintains compatibility
  - Performance improvements
- Increments PATCH version (x.y.Z)

## Commit Messages

The version bump workflow will automatically generate semantic commit messages:
- Major: "BREAKING CHANGE: Incompatible API changes"
- Minor: "feat: New backwards-compatible functionality"
- Patch: "fix: Backwards-compatible bug fixes"

## Pre-release Versions

For beta or release candidate versions, create a branch from main with the naming convention:
- Beta: `beta/vX.Y.Z-beta.N`
- RC: `rc/vX.Y.Z-rc.N`

## Notes

1. Always document API changes in your PR description
2. Include migration guides for major version bumps
3. Test thoroughly before merging version-changing PRs