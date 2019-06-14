## Build
```
docker build --build-arg arch=$(dpkg --print-architecture) -t jiesu/git-backup-gdrive:$(dpkg --print-architecture) .
```

## Run
Need:
* password - put the password in the file, single line. Put the file at ${PASSWORD_FILE} location

```
docker run --rm -v ${VOLUME}:/repos -e PASSWORD_FILE=/repos/password --link gdrive-service jiesu/git-backup-gdrive:armhf
```

