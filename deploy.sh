
#!/bin/bash
set -Eeuo pipefail

cd /home/ubuntu/lms

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:?Missing Docker Hub username}"
IMAGE_TAG="${IMAGE_TAG:?Missing image tag}"

COMPOSE_FILE="docker-compose.yml"
STATE_DIR=".deployment"
STATE_FILE="$STATE_DIR/previous.env"

mkdir -p "$STATE_DIR"

NEW_BACKEND="${DOCKERHUB_USERNAME}/lms-backend:${IMAGE_TAG}"
NEW_FRONTEND="${DOCKERHUB_USERNAME}/lms-frontend:${IMAGE_TAG}"

# Save previous image versions before deployment
OLD_BACKEND=$(docker inspect lms-backend \
  --format '{{.Config.Image}}' 2>/dev/null || true)

OLD_FRONTEND=$(docker inspect lms-frontend \
  --format '{{.Config.Image}}' 2>/dev/null || true)

rollback() {
    echo "Deployment failed. Starting rollback..."

    if [[ -n "$OLD_BACKEND" && -n "$OLD_FRONTEND" ]]; then
        export DOCKERHUB_USERNAME IMAGE_TAG

        IMAGE_TAG_BACKEND="${OLD_BACKEND##*:}"
        IMAGE_TAG_FRONTEND="${OLD_FRONTEND##*:}"

        IMAGE_TAG="$IMAGE_TAG_BACKEND" \
          docker compose pull backend

        IMAGE_TAG="$IMAGE_TAG_FRONTEND" \
          docker compose pull frontend

        IMAGE_TAG="$IMAGE_TAG_BACKEND" \
        DOCKERHUB_USERNAME="$DOCKERHUB_USERNAME" \
          docker compose up -d --no-deps backend

        IMAGE_TAG="$IMAGE_TAG_FRONTEND" \
        DOCKERHUB_USERNAME="$DOCKERHUB_USERNAME" \
          docker compose up -d --no-deps frontend

        echo "Previous application images restored."
    else
        echo "No previous image versions found."
        echo "Manual recovery may be required."
    fi
}

echo "Pulling new application images..."

docker pull "$NEW_BACKEND"
docker pull "$NEW_FRONTEND"

# Store previous versions for future recovery
if [[ -n "$OLD_BACKEND" && -n "$OLD_FRONTEND" ]]; then
    printf 'OLD_BACKEND=%s\nOLD_FRONTEND=%s\n' \
      "$OLD_BACKEND" "$OLD_FRONTEND" > "$STATE_FILE"
fi

echo "Deploying LMS application..."

export DOCKERHUB_USERNAME IMAGE_TAG

if ! docker compose up -d --no-build --no-deps backend; then
    rollback
    exit 1
fi

if ! docker compose up -d --no-build frontend; then
    rollback
    exit 1
fi

echo "Waiting for application health checks..."

for attempt in $(seq 1 18); do
    BACKEND_STATUS=$(docker inspect lms-backend \
      --format '{{.State.Health.Status}}' 2>/dev/null || true)

    FRONTEND_STATUS=$(docker inspect lms-frontend \
      --format '{{.State.Health.Status}}' 2>/dev/null || true)

    if [[ "$BACKEND_STATUS" == "healthy" && \
          "$FRONTEND_STATUS" == "healthy" ]] && \
       curl -fsS http://localhost/health >/dev/null; then
        echo "LMS deployment successful!"
        exit 0
    fi

    sleep 10
done

rollback
exit 1
