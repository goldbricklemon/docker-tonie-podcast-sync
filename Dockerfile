FROM python:3.12.11-slim-bullseye

ARG INCLUDE_FFMPEG=true
ARG TPS_VERSION

RUN if [ -z "$TPS_VERSION" ]; then \
    echo "TPS_VERSION build argument must be provided" >&2; exit 1; \
fi

RUN apt-get update && \
    if [ "$INCLUDE_FFMPEG" = "true" ]; then \
        apt-get -y --no-install-recommends install ffmpeg; \
    fi && \
    apt-get -y --no-install-recommends install cron && \
    if [ "$TPS_VERSION" = "main" ]; then \
        apt-get -y --no-install-recommends install git && \
        git clone --depth 1 https://github.com/alexhartm/tonie-podcast-sync.git /tmp/tps && \
        pip install --root-user-action ignore /tmp/tps && \
        rm -rf /tmp/tps; \
    else \
        pip install --root-user-action ignore tonie-podcast-sync==${TPS_VERSION}; \
    fi && \
    mkdir -p /root/.toniepodcastsync

WORKDIR /src

COPY src/start_schedule.sh .
RUN chmod +x start_schedule.sh

ENTRYPOINT [ "./start_schedule.sh" ]
CMD ["cron", "-f"]
