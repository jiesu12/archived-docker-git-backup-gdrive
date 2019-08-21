## Build
```
docker build --build-arg arch=$(dpkg --print-architecture) -t jiesu/git-backup-gdrive:$(date +%Y%m%d%H%M)-$(dpkg --print-architecture) .
```

## Run
Need:
* password - put the password in the file, single line. Put the file at ${PASSWORD_FILE} location
* gdrive server - hostname where the gdrive service is running.
```
docker run --rm -v ${VOLUME}:/repos -e PASSWORD_FILE=/repos/password -e GDRIVE_SERVER=media jiesu/git-backup-gdrive:<version>
```

