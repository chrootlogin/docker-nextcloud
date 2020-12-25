FROM docker:latest

ARG BUILDX_VER=0.5.1

ENV DOCKER_CLI_EXPERIMENTAL enabled

RUN mkdir -p /root/.docker && echo '{"experimental": "enabled"}' > /root/.docker/config.json

ADD https://github.com/docker/buildx/releases/download/v${BUILDX_VER}/buildx-v${BUILDX_VER}.linux-amd64 /root/.docker/cli-plugins/docker-buildx

RUN chmod +x /root/.docker/cli-plugins/docker-buildx

RUN apk add --no-cache -U curl