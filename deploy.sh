#!/bin/bash
set -Eeuo pipefail

cd /home/ubuntu/lms

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:?Missing Docker Hub username}"
IMAGE_TAG="${IMAGE_TAG:?Missing image tag}"

STATE_DIR=".deployment"
STATE_FILE="$STATE_DIR/previous.env"

mkdir -p "$STATE_DIR"

NEW_BACKEND="${DOCKERHUB_USERNAME}/lms-backend:${IMAGE_TAG}"
NEW_FRONTEND="${DOCKERHUB_USERNAME}/lms-frontend:${IMAGE_TAG}"

OLD_BACKEND=$(docker inspect lms-backend --format '{{.Config.Image}}' 2>/dev/null || true)
OLD_FRONTEND=$(docker inspect lms-frontend --format '{{.Config.Image}}' 2>/dev/null || true)

# Determine the previous shared image tag.
OLD_TAG=""

if [[ "$OLD_BACKEND" == "${DOCKERHUB_USERNAME}/lms-backend:"* &&
      "$OLD_FRONTEND" == "${DOCKERHUB_USERNAME}/lms-frontend:"* ]]; then

    BACKEND_TAG="${OLD_BACKEND##*:}"
    FRONTEND_TAG="${OLD_FRONTEND##*:}"

    if [[ "$BACKEND_TAG" == "$FRONTEND_TAG" ]]; then
        OLD_TAG="$BACKEND_TAG"
    fi
fi

# First pipeline deployment: use the existing local images.
if [[ -z "$OLD_TAG" ]]; then
    OLD_TAG="rollback-baseline"
fi

wait_for_health() {
    echo "Checking application health..."

    for attempt in $(seq 1 18); do
        BACKEND_STATUS=$(docker inspect lms-backend \
            --format '{{.State.Health.Status}}' 2>/dev/null || true)

        FRONTEND_STATUS=$(docker inspect lms-frontend \
            --format '{{.State.Health.Status}}' 2>/dev/null || true)

        if [[ "$BACKEND_STATUS" == "healthy" &&
              "$FRONTEND_STATUS" == "healthy" ]] &&
              curl -fsS http://localhost/health >/dev/null; then
            echo "Application health checks passed."
            return 0
        fi

        echo "Waiting for services... ($attempt/18)"
        sleep 10
    done

    return 1
}

rollback() {
    echo "Deployment failed. Rolling back to $OLD_TAG..."

    if ! docker image inspect \
        "${DOCKERHUB_USERNAME}/lms-backend:${OLD_TAG}" >/dev/null 2>&1; then
        docker pull "${DOCKERHUB_USERNAME}/lms-backend:${OLD_TAG}"
    fi

    if ! docker image inspect \
        "${DOCKERHUB_USERNAME}/lms-frontend:${OLD_TAG}" >/dev/null 2>&1; then
        docker pull "${DOCKERHUB_USERNAME}/lms-frontend:${OLD_TAG}"
    fi

    export DOCKERHUB_USERNAME
    export IMAGE_TAG="$OLD_TAG"

    docker compose up -d --no-build --pull never --no-deps backend frontend

    if wait_for_health; then
        echo "Rollback successful."
    else
        echo "ERROR: Rollback completed but health checks failed."
        return 1
    fi
}

echo "Pulling new application images..."

docker pull "$NEW_BACKEND"
docker pull "$NEW_FRONTEND"

echo "Deploying image tag: $IMAGE_TAG"

export DOCKERHUB_USERNAME IMAGE_TAG

if ! docker compose up -d --no-build --pull never --no-deps backend frontend; then
    rollback
    exit 1
fi

if ! wait_for_health; then
    rollback
    exit 1
fi

printf 'IMAGE_TAG=%s\n' "$IMAGE_TAG" > "$STATE_FILE"

echo "LMS deployment successful: $IMAGE_TAG"
