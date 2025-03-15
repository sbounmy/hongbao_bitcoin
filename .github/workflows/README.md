# GitHub Actions CI/CD Setup

This project uses GitHub Actions for continuous integration and deployment.

## Required Secrets

You need to set up the following secrets in your GitHub repository:

### For CI workflow:

- `RAILS_MASTER_KEY`: Required for decrypting Rails credentials in the test environment

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
   - Uses proper Rails credentials via RAILS_MASTER_KEY

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