#!/bin/bash

# Create .secrets.toml if tonie cloud username/password is passed as environment variables
if [[ -v TONIE_CLOUD_USERNAME ]] && [[ -v TONIE_CLOUD_PASSWORD ]]; 
then 
    # We use the dynaconf CLI to create the .secrets.toml expected by tps on the fly
    # dynaconf seems to miss a switch to ONLY generate the .secrets.toml, it always creates an emtpy settings.toml as well
    # Since we provide the settings.toml from the outside via bind-mount, we first create both files in /tmp and only move the secrets to the target directory
   /usr/local/bin/dynaconf init -f toml -p /tmp -s TONIE_CLOUD_ACCESS__USERNAME=$TONIE_CLOUD_USERNAME -s TONIE_CLOUD_ACCESS__PASSWORD=$TONIE_CLOUD_PASSWORD -y
   mv /tmp/.secrets.toml /root/.toniepodcastsync/
fi

# The actual sync command + log to docker logs
sync_cmd="/usr/local/bin/tonie-podcast-sync update-tonies > /proc/1/fd/1 2>/proc/1/fd/2"

# Sync right away if specified
if [[ -v TONIE_CLOUD_SYNC_NOW ]];
then
    eval " $sync_cmd"
fi

# Add tonie-podcasts-sync cronjob to custom cron file
echo "$CRON_SCHEDULE ${sync_cmd}" > /etc/cronjob
# Ensure cron file ends with empty line
echo -en '\n' >> /etc/cronjob
# Install cron file
crontab /etc/cronjob

# This script is executed using Docker ENTRYPOINT
# Hence, it recieves everything in Docker CMD as args
# This will exec the Docker CMD
exec "$@"
