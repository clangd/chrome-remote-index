# GCP server management scripts

This directory contains scripts used for managing the GCP project. They make use
of gcloud SDK so you need to install the SDK first, you can find instructions in
[here](https://cloud.google.com/sdk/docs/install).

## Configuration

### Common

GCP project name, machine type to use for VM instances and common base names can
be configured through [args.sh](args.sh).

### Docker options

Environment variables for the docker container can be configured in
[push_new_docker_image.sh](push_new_docker_image.sh). These contain:
- How to fetch the index artifact.
- Indexer project root.

### Serving infra

This is setup by running [initial_setup.sh](initial_setup.sh) script ones. By
default it will create 2 environments, one for live and one for staging.

Staging environment consists of a single instance group and a single VM in
europe-west, with a regional TCP loadbalancer in front. Loadbalancer accepts
trafic on port 50051.

Live environment has 2 instance groups one in us-central other in europe-west,
with a single VM in each of them. It has a global TCP loadbalancer in front.
Loadbalancer accepts traffic on port 5900.

Both environments use a TCP healthcheck on port 50051 and they only allow
ingress to that port.

## Rolling images back/forward

These can be done via [rollout_new_release.sh](rollout_new_release.sh) and
[rollback_to_release.sh](rollback_to_release.sh) scripts.

### Rolling out new images

`bash rollout_new_release.sh staging` will create a new docker image, pulling
the binaries from clangd/clangd/releases page, and push it to staging.

`bash rollout_new_release.sh live` will push the latest available docker image
in GCR into live, e.g. can be used to promote the latest staging image.

### Rolling back to older images

`bash rollback_to_release.sh [staging|live] IMAGE_FQN` can be used to change
images for staging|live instaces.

Fully qualified image names can be acquired either through GCP web UI or through
SDK with:
```
gcloud container images list-tags gcr.io/chrome-remote-index/chrome-remote-index-server
gcloud container images describe gcr.io/chrome-remote-index/chrome-remote-index-server@sha265:$SHORT_SHA$
```
