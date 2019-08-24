#!/bin/bash

set -e

GDRIVE_SERVICE="http://${GDRIVE_SERVER}:9000"
REPO_BASE="/repos"

if [ ! -f "${PASSWORD_FILE}" ]
then
  echo password file ${PASSWORD_FILE} not found
  exit 1
fi

password=$(cat ${PASSWORD_FILE})

echo
date
echo [gdrive backup] STARTING

cd ${REPO_BASE}
for repo in `find . -type d -name "*.git" -o -name "*.bin"`;do
  echo
  echo "[gdrive backup] Start working on ${repo}"
  repoName=$(echo $repo | sed 's#/#.#g')
  repoName="${repoName//../}"
  repoName="${repoName/.git/}"
  repoName="${repoName/.bin/}"

  echo [gdrive backup] directory - ${REPO_BASE}/${repo}
  cd ${REPO_BASE}/${repo}
  archive="${repoName}.7z"

  echo "[gdrive backup] compress and encrypt as 7z file"
  cd ${REPO_BASE}
  # these 7z options are important. have tried other options that failed, because 7z use a lot of memory, it could be killed by the system.
  7z a -mx -mmt2 -md48M -p${password} ${archive} ${repo} > /dev/null

  echo "[gdrive backup] Upload the repo..."
  curl -F "file=@${archive}" ${GDRIVE_SERVICE}
  rm ${archive}
done

date
echo [gdrive backup] FINISHED
echo

