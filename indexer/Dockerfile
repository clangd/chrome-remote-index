#===-- Dockerfile ---------------------------------------------------------===//
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===-----------------------------------------------------------------------===//
# Docker image used for building clangd index for Chromium.
#===-----------------------------------------------------------------------===//

FROM ubuntu:20.04

# GitHub Authentification token.
ARG TOKEN
ENV GITHUB_TOKEN=$TOKEN

RUN if [ -z "$GITHUB_TOKEN" ]; then \
      echo "GITHUB_TOKEN should be provided during build stage."; \
      exit -1; \
    fi;

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies.
RUN apt-get update; \
    apt-get install -y git curl sudo python3 python3-requests p7zip-full unzip \
                       python libc6-i386 lsb-release gnupg \
                       software-properties-common; \
    apt-get dist-upgrade -y;

# Install GitHub CLI (needed for uploading to GitHub Releases).
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; \
    apt-add-repository https://cli.github.com/packages; \
    apt-get update; \
    apt-get install -y gh;

COPY "download_latest_release_assets.py" "download_latest_release_assets.py"
COPY "run.sh" "run.sh"

ENTRYPOINT ["/run.sh"]
