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
                       python libc6-i386 lsb-release gnupg cron \
                       software-properties-common; \
    apt-get dist-upgrade -y;

# Install GitHub CLI (needed for uploading to GitHub Releases).
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; \
    apt-add-repository https://cli.github.com/packages; \
    apt-get update; \
    apt-get install -y gh;

COPY cronjob /etc/cron.d/cronjob
RUN chmod 0644 etc/cron.d/cronjob
RUN crontab /etc/cron.d/cronjob
RUN touch /var/log/indexer.log

COPY run.sh run.sh
COPY download_latest_release_assets.py download_latest_release_assets.py

RUN python3 download_latest_release_assets.py --output-name clangd_indexing_tools.zip --asset-prefix clangd_indexing_tools-linux && \
    unzip clangd_indexing_tools.zip && \
    rm clangd_indexing_tools.zip

COPY prepare.sh prepare.sh
RUN chmod +x /prepare.sh

RUN echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> /etc/environment

ENTRYPOINT /prepare.sh >> /var/log/prepare.log 2>&1 && \
           cron start && \
           tail -f /var/log/indexer.log
