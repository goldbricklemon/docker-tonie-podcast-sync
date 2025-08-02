FROM python:3.12.11-slim-bullseye

RUN apt-get update && \
    apt-get -y --no-install-recommends install cron ffmpeg && \
    pip install --root-user-action ignore tonie-podcast-sync==3.1.2 && \
    mkdir -p /root/.toniepodcastsync

WORKDIR /src

COPY src/start_schedule.sh .
RUN chmod +x start_schedule.sh


ENTRYPOINT [ "./start_schedule.sh" ]
CMD ["cron", "-f"]
