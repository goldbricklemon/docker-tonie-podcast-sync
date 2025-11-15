FROM python:3.12.11-slim-bullseye

ARG INCLUDE_FFMPEG=true

RUN apt-get update && \
    if [ "$INCLUDE_FFMPEG" = "true" ]; then \
        apt-get -y --no-install-recommends install ffmpeg; \
    fi && \
    apt-get -y --no-install-recommends install cron && \
    pip install --root-user-action ignore tonie-podcast-sync==3.2.1 && \
    mkdir -p /root/.toniepodcastsync

WORKDIR /src

COPY src/start_schedule.sh .
RUN chmod +x start_schedule.sh


ENTRYPOINT [ "./start_schedule.sh" ]
CMD ["cron", "-f"]
