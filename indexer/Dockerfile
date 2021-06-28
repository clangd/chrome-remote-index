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
ARG DEBIAN_FRONTEND=noninteractive
ENV GITHUB_TOKEN=$TOKEN

RUN if [ -z "$GITHUB_TOKEN" ]; then \
      echo "GITHUB_TOKEN should be provided during build stage."; \
      exit -1; \
    fi;

# Install dependencies.
RUN apt-get update; \
    apt-get install -y git curl python3 python3-requests p7zip-full unzip \
                       cron lsb-release sudo tzdata; \
    apt-get dist-upgrade -y;

# Install GitHub CLI (needed for uploading to GitHub Releases).
ADD https://github.com/cli/cli/releases/download/v1.11.0/gh_1.11.0_linux_amd64.deb gh.deb
RUN dpkg -i gh.deb && rm gh.deb

COPY cronjob /etc/cron.d/cronjob
RUN chmod 0644 etc/cron.d/cronjob
RUN crontab /etc/cron.d/cronjob
RUN touch /var/log/indexer.log

COPY run.sh run.sh
COPY download_latest_release_assets.py download_latest_release_assets.py

RUN python3 download_latest_release_assets.py --output-name \
      clangd_indexing_tools.zip --asset-prefix clangd_indexing_tools-linux && \
    unzip clangd_indexing_tools.zip && \
    rm clangd_indexing_tools.zip

COPY prepare.sh prepare.sh
RUN chmod +x /prepare.sh

RUN echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> /etc/environment

COPY entry_point.sh entry_point.sh
RUN chmod +x /entry_point.sh

ENTRYPOINT ["/entry_point.sh"]
