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


file_list=$(curl ${GDRIVE_SERVICE})

function fileExist {
  echo "${file_list}" | grep ${1} | wc -l
}

function getLocalUpdateTime {
  cd $1
  if [[ "$1" == *.git ]];then
    git for-each-ref --sort=-committerdate refs/heads/ --format="%(committerdate:format:%s)" | head -1
  else
    find . -type f -not -name '.gitbin' -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1
  fi
}

function compressFile {
  echo "[gdrive backup] compress and encrypt as 7z file"
  cd ${REPO_BASE}
  # these 7z options are important. have tried other options that failed, because 7z use a lot of memory, it could be killed by the system.
  7z a -mx -mmt2 -md48M -p${password} ${1} ${2} > /dev/null
}

function uploadFile {
  echo "[gdrive backup] Upload the repo..."
  cd ${REPO_BASE}
  curl -s -F "file=@${1}" ${GDRIVE_SERVICE} > /dev/null
  echo "[gdrive backup] Uploaded file ${1}"
}

function cleanOldFiles {
  echo "[gdrive backup] clean old files in gdrive"
  # tail -n +<number> skip number of lines
  echo "${file_list}" | grep ${1} | sort | tail -n +8 | while read l
  do
    local fileId=$(echo $l | cut -d' ' -f2)
    curl -s -X 'DELETE' ${GDRIVE_SERVICE}/${fileId}
    echo "[gdrive backup] Deleted old file ${l}"
  done
}

cd ${REPO_BASE}
# clean any left over from last run
rm -f *.7z.*
for repoRelDir in `find . -type d -name "*.git" -o -name "*.bin"`;do
  echo
  echo "[gdrive backup] Start working on ${repoRelDir}"
  filenameNoTime=$(echo ${repoRelDir} | sed 's#/#.#g')
  filenameNoTime="${filenameNoTime//../}"
  filenameNoTime="${filenameNoTime/.git/}"
  filenameNoTime="${filenameNoTime/.bin/}"
  repoAbsDir=${REPO_BASE}/${repoRelDir}
  localUpdateTime=$(getLocalUpdateTime ${repoAbsDir})
  filenameWithTime="${filenameNoTime}.7z.${localUpdateTime}"

  echo [gdrive backup] directory - ${repoAbsDir}

  if [[ "$(fileExist ${filenameWithTime})" == 0 ]];then
    compressFile ${filenameWithTime} ${repoRelDir}
    uploadFile ${filenameWithTime}
    rm ${REPO_BASE}/${filenameWithTime}
    cleanOldFiles ${filenameNoTime}
  else
    echo "[gdrive backup] No new changes."
  fi
done

date
echo "[gdrive backup] FINISHED"
echo

