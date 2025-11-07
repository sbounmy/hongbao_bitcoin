# Cloudflare R2 Mount Setup for Blog Images

This guide explains how to set up automatic image syncing between your local `app/content/assets/blog` directory and Cloudflare R2 storage using rclone mount.

> **⚠️ Important for macOS Users:** The Homebrew version of rclone does NOT support mount functionality on macOS. You must use the official binary from rclone.org. See installation instructions below.

## Prerequisites

1. **Install official rclone binary** (required for mount support on macOS)

   ⚠️ **Important**: The Homebrew version of rclone does NOT support mounting on macOS.
   You must install the official binary instead:

   ```bash
   # Install official rclone using our r2 command
   bin/r2 install

   # Enter your password when prompted for sudo
   # This installs rclone to /usr/local/bin/rclone

   # Verify installation
   which rclone     # Should show /usr/local/bin/rclone
   rclone version   # Should show the version installed
   ```

   If you previously installed rclone via Homebrew:
   ```bash
   # After installing official binary, optionally remove Homebrew version
   brew uninstall rclone
   ```

2. **Install FUSE-T** (required for mounting)
   ```bash
   brew install --cask fuse-t
   ```

   Note: You may need to allow FUSE-T in System Settings > Privacy & Security after installation.

## Configuration

All configuration is handled via environment variables in your `.env` file. No rclone config files are needed.

### 1. Set up Cloudflare R2 Buckets

Create two buckets in your Cloudflare R2 dashboard:
- `hongbao-development` - For development environment
- `hongbao-production` - For production environment

### 2. Create R2 API Token

1. Go to Cloudflare Dashboard > R2 > Manage R2 API Tokens
2. Create a new token with:
   - Name: `hongbao-rclone`
   - Permissions: Admin Read & Write
   - TTL: No expiry or appropriate duration
3. Save the credentials:
   - Access Key ID
   - Secret Access Key
   - Account ID (from R2 dashboard URL)

### 3. Configure Environment Variables

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` and add your R2 credentials:
```bash
# Development Bucket
RCLONE_CONFIG_R2DEV_TYPE=s3
RCLONE_CONFIG_R2DEV_PROVIDER=Cloudflare
RCLONE_CONFIG_R2DEV_ACCESS_KEY_ID=your_access_key_here
RCLONE_CONFIG_R2DEV_SECRET_ACCESS_KEY=your_secret_key_here
RCLONE_CONFIG_R2DEV_ENDPOINT=https://your_account_id.r2.cloudflarestorage.com
RCLONE_CONFIG_R2DEV_ACL=private
RCLONE_CONFIG_R2DEV_REGION=auto

# Production Bucket
RCLONE_CONFIG_R2PROD_TYPE=s3
RCLONE_CONFIG_R2PROD_PROVIDER=Cloudflare
RCLONE_CONFIG_R2PROD_ACCESS_KEY_ID=your_access_key_here
RCLONE_CONFIG_R2PROD_SECRET_ACCESS_KEY=your_secret_key_here
RCLONE_CONFIG_R2PROD_ENDPOINT=https://your_account_id.r2.cloudflarestorage.com
RCLONE_CONFIG_R2PROD_ACL=private
RCLONE_CONFIG_R2PROD_REGION=auto
```

### 4. Test Connection

```bash
# Test R2 connections
bin/r2 test

# Expected output:
# Testing development bucket (r2dev)... ✓ Connected
# Testing production bucket (r2prod)... ✓ Connected
```

## Usage

### Mount Development Bucket

```bash
# Mount R2 development bucket
bin/r2 mount

# This will:
# 1. Mount hongbao-development to mounts/r2-dev/
# 2. Create symlink from app/content/assets/blog → mounts/r2-dev/blog/
# 3. Any files saved to app/content/assets/blog auto-sync to R2
```

### Check Mount Status

```bash
# Check if mounted
bin/r2 status
```

### Unmount

```bash
# Unmount when done
bin/r2 unmount
```

### List Files

```bash
# List files in development bucket
bin/r2 ls
bin/r2 ls dev blog/2024      # Specific path in dev

# List files in production bucket
bin/r2 ls prod
bin/r2 ls prod blog/2024     # Specific path in prod
```

### Sync Between Environments

The sync command requires explicit source and destination environments and a typed confirmation phrase for safety.

```bash
# Sync entire blog from dev to production
bin/r2 sync --from dev --to prod
# Type: SYNC FROM DEVELOPMENT TO PRODUCTION

# Restore from production to development
bin/r2 sync --from prod --to dev
# Type: SYNC FROM PRODUCTION TO DEVELOPMENT

# Sync specific path between environments
bin/r2 sync --from dev --to prod --path blog/2024
# Type: SYNC FROM DEVELOPMENT TO PRODUCTION

# Short form flags also work
bin/r2 sync -f dev -t prod -p blog/2024/my-post
```

**Safety Features:**
- No default sync direction - must specify --from and --to
- Requires typing the exact confirmation phrase (e.g., "SYNC FROM DEVELOPMENT TO PRODUCTION")
- Shows file preview before syncing
- Special warning when syncing to production

### Backup Production

```bash
# Create timestamped backup before major updates
bin/r2 backup
```

## Workflow

### Initial Setup (First Time Only)

```bash
# 1. Install official rclone binary
bin/r2 install

# 2. Install FUSE-T if not already installed
brew install --cask fuse-t

# 3. Configure R2 credentials in .env file
cp .env.example .env
# Edit .env with your R2 credentials

# 4. Test connection
bin/r2 test
```

### Development Workflow

#### Option 1: Automatic Mount with bin/dev (Recommended)

The R2 mount is now integrated into the development server and will start automatically:

```bash
bin/dev
# This starts Rails, CSS, JS, Stripe webhook, AND R2 mount
```

The mount will run in the foreground and be managed by foreman along with other services.

#### Option 2: Manual Mount

If you prefer to mount manually or need to mount without starting the full dev server:

1. **Mount the development bucket:**
   ```bash
   bin/r2 mount
   ```

2. **Work on your blog content:**
   - Save images to `public/blog-images/`
   - They automatically sync to R2 development bucket
   - Images are accessible at `/blog-images/` URL path
   - Access via development CDN URL

3. **When ready for production:**
   ```bash
   # Optional: backup production first
   bin/r2 backup

   # Sync to production
   bin/r2 sync
   ```

4. **Unmount when done:**
   ```bash
   bin/r2 unmount
   ```

### Writing Blog Articles

When writing articles in `app/content/`, reference images like:

```erb
<!-- Development -->
<%= cdn_image_tag('blog/2024/my-post/image.png') %>

<!-- The cdn_helper.rb automatically uses the correct CDN URL -->
```

## Directory Structure

```
hongbao/
├── public/
│   └── blog-images/       # Symlink to mount (auto-created)
├── mounts/
│   └── r2-dev/            # Mount point (auto-created)
│       └── blog/          # Your blog images appear here
├── bin/
│   └── r2                 # Main R2 management command (includes install, mount, sync, etc.)
├── Procfile.dev           # Includes r2 mount for automatic startup
└── log/
    └── rclone-mount.log   # Mount operation logs
```

## Troubleshooting

### Mount fails with "rclone mount is not supported on MacOS"

This error occurs when using the Homebrew version of rclone. You must install the official binary:
```bash
# Install official rclone
bin/r2 install

# Remove Homebrew version if needed
brew uninstall rclone

# Verify correct version is used
which rclone  # Should show /usr/local/bin/rclone
```

### Mount fails with "FUSE-T not found"

Install FUSE-T and allow it in System Settings:
```bash
brew install --cask fuse-t
```

Then go to System Settings > Privacy & Security and allow FUSE-T.

### Empty directories don't appear in R2/Cloudflare Dashboard

**This is normal behavior for object storage.** R2/S3 only stores files, not empty directories.

To make a directory visible:
1. Add at least one file to the directory
2. Wait ~5 seconds for the mount to sync (configured delay)
3. The directory will then appear in the Cloudflare R2 web interface

Example:
```bash
# Create directory - won't appear in R2 yet
mkdir app/content/assets/blog/new-article

# Add a file - now it will appear in R2
echo "test" > app/content/assets/blog/new-article/test.txt

# Verify in R2
bin/r2 ls dev blog/new-article
```

### "Access Denied" errors

Check your R2 API token permissions. You need Admin Read & Write access.


### Files not syncing

1. Ensure mount is active with `bin/r2 status`
2. Wait 5 seconds (configured upload delay)
3. Check logs for errors: `tail -f log/rclone-mount.log`
4. Verify with: `bin/r2 ls dev blog/your-folder`

### "Operation not permitted" error with ls

This is a known issue with FUSE mounts on macOS and can be safely ignored:
```bash
# May show "Operation not permitted" but still works
ls -la app/content/assets/blog/some-folder/

# Use this instead to verify files
bin/r2 ls dev blog/some-folder
```
The mount is still functioning correctly - files will sync to R2 despite this error.

### "Device or resource busy" when unmounting

Close any applications or terminals that might be accessing files in the mount:
```bash
lsof | grep r2-dev
```

## Important Notes

- **Official rclone required:** Must use official binary from rclone.org, NOT Homebrew version (for macOS mount support)
- **No credentials in code:** All R2 credentials are in environment variables
- **Gitignored:** Mount directories and symlinks are excluded from git
- **Development safety:** Using separate dev/prod buckets prevents accidents
- **Manual promotion:** Must explicitly sync dev→prod with typed confirmation phrase
- **Empty directories:** Won't appear in R2 until they contain at least one file

## CDN URLs

- Development: Files in `hongbao-development` bucket
- Production: Files in `hongbao-production` bucket at `https://cdn.hongbaob.tc`

Ensure your Cloudflare R2 buckets are configured with appropriate public access or custom domains as needed.