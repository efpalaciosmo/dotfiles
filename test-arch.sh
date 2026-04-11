#!/bin/sh
set -eu

if ! command -v podman >/dev/null 2>&1; then
    printf "Error: podman is required but was not found in PATH.\n" >&2
    exit 1
fi

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
IMAGE="${IMAGE:-docker.io/library/archlinux:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-dotfiles-arch-test}"
CONTAINER_USER="${CONTAINER_USER:-dev}"
CONTAINER_PASSWORD="${CONTAINER_PASSWORD:-password}"
CUSTOM_IMAGE="${CUSTOM_IMAGE:-dotfiles-arch-user}"

printf "Using image: %s\n" "$IMAGE"
printf "Custom image: %s\n" "$CUSTOM_IMAGE"
printf "Container name: %s\n" "$CONTAINER_NAME"
printf "Container user: %s\n" "$CONTAINER_USER"

if podman container exists "$CONTAINER_NAME"; then
    printf "Removing existing container '%s'...\n" "$CONTAINER_NAME"
    podman rm -f "$CONTAINER_NAME" >/dev/null
fi

printf "Pulling Arch Linux image...\n"
podman pull "$IMAGE"

printf "Building custom image with non-root user...\n"
podman build \
    --build-arg "BASE_IMAGE=$IMAGE" \
    --build-arg "CONTAINER_USER=$CONTAINER_USER" \
    --build-arg "CONTAINER_PASSWORD=$CONTAINER_PASSWORD" \
    -t "$CUSTOM_IMAGE" \
    -f "$ROOT_DIR/system/Containerfile.arch-test" \
    "$ROOT_DIR" >/dev/null

printf "Starting container as non-root user...\n"
podman run -d --name "$CONTAINER_NAME" --user "$CONTAINER_USER" "$CUSTOM_IMAGE" sleep infinity >/dev/null

printf "Copying dotfiles into container...\n"
podman cp "$ROOT_DIR/." "$CONTAINER_NAME:/home/$CONTAINER_USER/dotfiles"
podman exec --user root "$CONTAINER_NAME" /bin/bash -lc "chown -R $CONTAINER_USER:$CONTAINER_USER /home/$CONTAINER_USER/dotfiles"

printf "\nContainer ready. Enter with your non-root user and run setup manually:\n"
printf "  podman exec -it --user %s %s /bin/bash\n" "$CONTAINER_USER" "$CONTAINER_NAME"
printf "\nInside the container run:\n"
printf "  cd ~/dotfiles\n"
printf "  ./setup.sh\n"
printf "\nPassword for '%s': %s\n" "$CONTAINER_USER" "$CONTAINER_PASSWORD"

printf "Stop/remove: podman rm -f %s\n" "$CONTAINER_NAME"
