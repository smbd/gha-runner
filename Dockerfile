# syntax=docker/dockerfile:1.4

ARG DEBIAN_RELEASE=bookworm

FROM debian:${DEBIAN_RELEASE}-slim

ARG RUNNER_VER=2.312.0
ARG FIXUID_VER=0.6.0
ARG DEBIAN_RELEASE

SHELL ["/bin/bash","-c"]

RUN groupadd runner && useradd -s /bin/bash -m -g runner runner

RUN apt-get update \
  && DEBIANIN_FRONTEND=noninteractive apt-get install -y \
       liblttng-ust1 \
       libicu72 \
       wget \
       gnupg \
  && case $(uname -m) in "aarch64") RUNNER_ARCH=ARM64; FIXUID_ARCH=arm64; ;; "x86_64") RUNNER_ARCH=x64; FIXUID_ARCH=amd64; ;; *) echo "unsupported arch, abort" ; exit 1; ;; esac \
  && wget -q -O - https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VER}.tar.gz | tar -xz -C /home/runner -f - \
  && chown -R runner:runner /home/runner \
  && wget -q -O - https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VER}/fixuid-${FIXUID_VER}-linux-${FIXUID_ARCH}.tar.gz | tar -xz -C /usr/local/bin -f - \
  && chmod 4755 /usr/local/bin/fixuid \
  && mkdir /etc/fixuid \
  && wget -q -O - https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${DEBIAN_RELEASE} stable" > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && DEBIANIN_FRONTEND=noninteractive apt-get install -y docker-ce docker-buildx-plugin \
  && usermod -aG docker runner \
  && apt-get purge -y --auto-remove wget gnupg \
  && rm -rf /var/lib/apt/lists/*
COPY fixuid.yml /etc/fixuid/config.yml

COPY --chown=runner:runner entrypoint.sh /home/runner

USER runner

WORKDIR /home/runner

ENTRYPOINT ["/usr/local/bin/fixuid","-q","/home/runner/entrypoint.sh"]

# run: docker run --rm -u $(id -u):$(id -g) --group-add $(getent group docker | cut -d: -f3) -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/relm:/home/runner/relm IMAGE_NAME REPO_URL GITHUB_PRIVATE_ACCESS_TOKEN
