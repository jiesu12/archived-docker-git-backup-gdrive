#!/bin/bash

set -e

GDRIVE_SERVICE='http://gdrive-service:9000'
REPO_BASE="/repos"
GDRIVE_WORK_DIR="/tmp/gdrive"
SKIP_REPOS="" # space delimited repo names
SKIP_DIRS="photo old" # space delimited dir names, e.g, "photo old"

function storeExistingFiles {
  while read line;do
    local name=$(echo $line | cut -f1 -d ' ')
    local id=$(echo $line | cut -f2 -d ' ')
    name=${name/.7z./ }
    local reponame=$(echo $name | cut -f 1 -d' ')
    local updatetime=$(echo $name | cut -f 2 -d' ')
    echo $id > ${GDRIVE_WORK_DIR}/${reponame}.7z.id
    echo $updatetime > ${GDRIVE_WORK_DIR}/${reponame}.lastbackuptime
  done
}

if [ ! -f "${PASSWORD_FILE}" ]
then
  echo password file ${PASSWORD_FILE} not found
  exit 1
fi

password=$(cat ${PASSWORD_FILE})

rm -rf $GDRIVE_WORK_DIR
mkdir -p $GDRIVE_WORK_DIR

echo "[gdrive backup] Found existing files on gdrive"
file_list=$(curl ${GDRIVE_SERVICE})
if [[ "${file_list}" == Failed* ]];then
  echo "[gdrive backup] Cancel backup because gdrive error - ${file_list}"
  exit 1
fi

echo "$file_list" | storeExistingFiles

echo
date
echo [gdrive backup] STARTING

cd ${REPO_BASE}
for repo in `find . -type d -name "*.git"`;do
  repoName=$(echo $repo | sed 's#/#.#g')
  repoName="${repoName//../}"
  repoName="${repoName/.git/}"
  echo
  echo "[gdrive backup] Start working on ***${repoName}***"

  for skipRepo in $SKIP_REPOS
  do
    if [ "$repoName" == "${skipRepo}" ]
    then
      echo "Skip archive ${repoName}"
      continue 2
    fi
  done

  for skipDir in $SKIP_DIRS
  do
    if [[ "$repo" == *"${skipDir}"* ]]
    then
      echo "Skip archive ${repoName} because it is under ${skipDir}"
      continue 2
    fi
  done

  echo [gdrive backup] directory - ${REPO_BASE}/${repo}
  cd ${REPO_BASE}/${repo}
  echo "[gdrive backup] Check last commit timestamp"
  lastCommitTime=`git log -1 --pretty=format:%ct`
  lastCommitTimeFile="${GDRIVE_WORK_DIR}/${repoName}.lastbackuptime"
  if [ -f "${lastCommitTimeFile}" ];then
    lastBackupTime=`cat ${lastCommitTimeFile}`
  else
    lastBackupTime=0
  fi
  archive="${repoName}.7z"
  idFile="${GDRIVE_WORK_DIR}/${archive}.id"
  if [ "${lastCommitTime}" -gt "${lastBackupTime}" ];then
    echo "[gdrive backup] Last commit time is ${lastCommitTime}, last backup time is ${lastBackupTime}"
    echo "[gdrive backup] There are new commits since last backup, will do gdrive backup"
    echo "[gdrive backup] compress and encrypt as 7z file"
    cd ${REPO_BASE}
    archive=${archive}.${lastCommitTime}
    # these 7z options are important. have tried other options that failed, because 7z use a lot of memory, it could be killed by the system.
    7z a -mx -mmt2 -md48M -p${password} ${archive} ${repo} > /dev/null
    echo "[gdrive backup] Upload the repo..."
    curl -F "file=@${archive}" ${GDRIVE_SERVICE}
    rm ${archive}
    if [ -f "${idFile}" ];then
      echo "[gdrive backup] Remove old backup from gdrive"
      oldBackupFileId=`cat ${idFile}`
      curl -X 'DELETE' ${GDRIVE_SERVICE}/${oldBackupFileId}
    fi
  else
    echo "[gdrive backup] No new commit since last backup, will skip gdrive backup"
  fi
  if [ -f "${idFile}" ];then
    echo "[gdrive backup] Remove ID file"
    rm ${idFile}
  fi
done

date
echo [gdrive backup] FINISHED
echo
