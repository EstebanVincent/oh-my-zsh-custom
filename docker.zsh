# Docker aliases
alias up='docker compose up'
alias dcu='docker compose up'
alias upb='docker compose up --build'
alias dcub='docker compose up --build'
alias dbp='docker builder prune -f'
alias dip='docker image prune -f'

# Docker functions

# Build Docker image locally
# Usage: dbuild <image_name>

function dbuild() {
  local image_name="$1"

  if [[ -z "$image_name" ]]; then
    echo "Usage: dbuild <image_name>" >&2
    return 1
  fi

  # Auto-detect platform
  local platform
  if [[ "$(uname -m)" == "arm64" || "$(uname -m)" == "aarch64" ]]; then
    platform="linux/arm64"
  else
    platform="linux/amd64"
  fi

  echo "Detected platform: $platform"

  echo "Building Docker image for $platform: $image_name"
  if ! docker build --platform "$platform" -t "$image_name" .; then
    echo "Error: Failed to build image for $platform" >&2
    return 1
  fi

  echo "Successfully built local image: $image_name"
}

# Build and push Docker image to Azure Container Registry
# Usage: dacr <image_name> <acr_name>

function dacr() {
  local image_name="$1"
  local acr_name="$2"

  if [[ -z "$image_name" || -z "$acr_name" ]]; then
    echo "Usage: dacr <image_name> <acr_name>" >&2
    return 1
  fi

  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)

  local acr_url="${acr_name}.azurecr.io"
  local full_image_timestamp="${acr_url}/${image_name}:${timestamp}"
  local full_image_latest="${acr_url}/${image_name}:latest"

  echo "Logging into ACR: $acr_name"
  if ! az acr login --name "$acr_name"; then
    echo "Error: Failed to login to ACR" >&2
    return 1
  fi

  echo "Building and pushing multi-platform Docker image for ACR: $image_name"
  if ! docker buildx build --platform linux/amd64,linux/arm64 \
      -t "$full_image_timestamp" -t "$full_image_latest" --push .; then
    echo "Error: Failed to buildx build and push multi-platform image" >&2
    return 1
  fi

  echo "Successfully built and pushed $image_name to $acr_name"
  echo "Tags: $timestamp, latest"
}

# Run Docker container with optional arguments
# Usage: drun <image_name> [additional_docker_args...]

function drun() {
  local image_name="$1"
  shift

  if [[ -z "$image_name" ]]; then
    echo "Usage: drun <image_name> [additional_docker_args...]" >&2
    echo "Examples:" >&2
    echo "  drun myapp" >&2
    echo "  drun myapp -p 8080:8080" >&2
    echo "  drun myapp -p 3000:3000 -v \$(pwd):/app" >&2
    return 1
  fi

  local container_name="${image_name}-container"
  
  # Auto-detect platform
  local platform
  if [[ "$(uname -m)" == "arm64" ]]; then
    platform="linux/arm64"
  else
    platform="linux/amd64"
  fi
  
  echo "Running Docker container: $container_name from image: $image_name (platform: $platform)"
  
  if [[ -f ".env" ]]; then
    echo "Found .env file - including environment variables"
    docker run --rm -it --platform "$platform" --env-file .env --name "$container_name" "$@" "$image_name"
  else
    echo "No .env file found - running without environment file"
    docker run --rm -it --platform "$platform" --name "$container_name" "$@" "$image_name"
  fi
}

# Execute bash in a running Docker container
# Usage: dex <container_id_or_name>

function dex() {
  local container="$1"

  if [[ -z "$container" ]]; then
    echo "Usage: dex <container_id_or_name>" >&2
    return 1
  fi

  docker exec -it "$container" /bin/bash
}
