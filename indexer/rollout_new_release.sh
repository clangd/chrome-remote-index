source args.sh

set -ex

# Start by creating a new image.
. push_new_docker_image.sh $@

# Restarting VM instance will start with latest docker image.
gcloud compute --project=$PROJECT_ID instances stop --zone=$VM_ZONE $VM_NAME
gcloud compute --project=$PROJECT_ID instances start --zone=$VM_ZONE $VM_NAME
