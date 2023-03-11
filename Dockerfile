FROM perl:5.37.9-slim-threaded-bullseye
LABEL maintainer="Andrejs Gostevs <andrejs.gostevs@gmail.com>"

ARG APP_ROOT="/opt/mojolicious"
ARG APP_PORT=8080

ARG TEMPORARY_PACKAGES="gcc"
ARG PERMAMENT_PACKAGES=""

EXPOSE ${APP_PORT}

# Install packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends ${TEMPORARY_PACKAGES} ${PERMAMENT_PACKAGES}

WORKDIR ${APP_ROOT}

# Install application modules
COPY application/cpanfile .
RUN true \
    && cpm install -g \
    && rm -f cpanfile

# Create application user
RUN true \
    && groupadd -g 1000 mojolicious \
    && useradd -u 1000 -g mojolicious mojolicious

# Cleanup
RUN true \
    && apt-mark auto ${TEMPORARY_PACKAGES} > /dev/null \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/cache/apt/* /var/lib/apt/lists/* \
    && rm -rf /root/.cpanm /tmp/*

# Import application
RUN chown mojolicious:mojolicious ${APP_ROOT}
COPY --chown=mojolicious:mojolicious application/ .

USER mojolicious
ENV MOJO_LISTEN="http://*:${APP_PORT}"

ENTRYPOINT ["./script/application"]