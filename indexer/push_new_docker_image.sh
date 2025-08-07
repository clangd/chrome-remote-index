source args.sh

set -ex

TOKEN="$1"
if [ -z "$TOKEN" ]; then \
  echo "Usage: $0 GITHUB_TOKEN_FOR_UPLOADING_INDEX"; \
  exit -1; \
fi;

TEMP_DIR="$(mktemp -d)"
# Make sure we delete TEMP_DIR on exit.
trap "rm -r $TEMP_DIR" EXIT

# Copy all the necessary files for docker image into a temp directory and move
# into it.
cp Dockerfile "$TEMP_DIR/"
cp cronjob "$TEMP_DIR/"
cp run.sh "$TEMP_DIR/"
cp ../download_latest_release_assets.py "$TEMP_DIR/"
cp prepare.sh "$TEMP_DIR/"
cp entry_point.sh "$TEMP_DIR/"
cd "$TEMP_DIR"

# Build the image, tag it for GCR and push.
docker build --build-arg TOKEN="$TOKEN" -t "$IMAGE_IN_GCR" .
docker push "$IMAGE_IN_GCR"
