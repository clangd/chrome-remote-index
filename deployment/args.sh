#!/bin/bash
# Abort script on failure and print commands as we execute them.
set -x -e

# GCP project to configure.
PROJECT_ID="chrome-remote-index"

# Basename for instance templates, can be suffixed with image SHAs.
BASE_TEMPLATE_NAME="${PROJECT_ID}-server-template"

# Machine type to use for index serving VM instances.
# 2 vCPUs and 16GB ram is enough for serving chrome-index.
# https://cloud.google.com/compute/docs/machine-types#e2_high-memory_machine_types
MACHINE_TYPE="e2-highmem-2"

# Fully qualified name for the server image in GCR.
IMAGE_IN_GCR="gcr.io/${PROJECT_ID}/${PROJECT_ID}-server"

# Used as base name for instance groups and machine instances.
BASE_INSTANCE_NAME="${PROJECT_ID}-server"

# Following options are used by push_new_docker_image.sh to configure container
# for fetching new index artifacts and consuming them.

# Which github repository to use for fetching index artifacts.
INDEX_REPO="clangd/chrome-remote-index"

# Artifact prefix to fetch the index from and port number to serve it on.
# Separated by `:`.
INDEX_ASSET_PORT_PAIRS="chrome-index-linux:50051 \
  chrome-index-chromeos:50052 \
  chrome-index-android:50053 \
  chrome-index-fuchsia:50054 \
  chrome-index-chromecast-linux:50055 \
  chrome-index-chromecast-android:50056"

# Absolute path to project root on indexer machine, passed to
# clangd-index-server.
INDEXER_PROJECT_ROOT="/chromium/src/"
