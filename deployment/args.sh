#!/bin/bash
# Abort script on failure and print commands as we execute them.
set -x -e

# GCP project to configure.
PROJECT_ID="chrome-remote-index"

# Basename for instance templates, can be suffixed with image shas.
BASE_TEMPLATE_NAME="${PROJECT_ID}-server-template"

# Machine type to use for index serving VM instances.
# 2 vCPUs and 16GB ram is enough for serving chrome-index.
MACHINE_TYPE="e2-highmem-2"

# Fully qualified name for the server image in google cloud repo.
IMAGE_IN_GCR="gcr.io/${PROJECT_ID}/${PROJECT_ID}-server"

# Used as base name for instance groups and machine instances.
BASE_INSTANCE_NAME="${PROJECT_ID}-server"

# Which github repository to use for fetching index artifacts.
INDEX_REPO="clangd/chrome-remote-index"

# Prefix to detect index asset.
INDEX_ASSET_PREFIX="chrome-index"

# Absolute path to project root on indexer machine.
INDEXER_PROJECT_ROOT="/chromium/src/"
