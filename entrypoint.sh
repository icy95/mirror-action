#!/usr/bin/env bash
set -e

if [[ "${DEBUG}" -eq "true" ]]; then
    set -x
fi

git config --global --add safe.directory /github/workspace

GIT_USERNAME=${INPUT_GIT_USERNAME:-${GIT_USERNAME:-"git"}}
REMOTE=${INPUT_REMOTE:-"$*"}
GIT_SSH_PRIVATE_KEY=${INPUT_GIT_SSH_PRIVATE_KEY}
GIT_SSH_PUBLIC_KEY=${INPUT_GIT_SSH_PUBLIC_KEY}
GIT_PUSH_ARGS=${INPUT_GIT_PUSH_ARGS:-"--force --all"}
GIT_SSH_NO_VERIFY_HOST=${INPUT_GIT_SSH_NO_VERIFY_HOST}
GIT_SSH_KNOWN_HOSTS=${INPUT_GIT_SSH_KNOWN_HOSTS}





git config --global credential.username "${GIT_USERNAME}"


if [[ "${GIT_SSH_PRIVATE_KEY}" != "" ]]; then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
    echo "${GIT_SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
    if [[ "${GIT_SSH_PUBLIC_KEY}" != "" ]]; then
        echo "${GIT_SSH_PUBLIC_KEY}" > ~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa.pub
    fi
    chmod 600 ~/.ssh/id_rsa
    if [[ "${GIT_SSH_KNOWN_HOSTS}" != "" ]]; then
      echo "${GIT_SSH_KNOWN_HOSTS}" > ~/.ssh/known_hosts
      git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=~/.ssh/known_hosts"
    else
      if [[ "${GIT_SSH_NO_VERIFY_HOST}" != "true" ]]; then
        echo "WARNING: no known_hosts set and host verification is enabled (the default)"
        echo "WARNING: this job will fail due to host verification issues"
        echo "Please either provide the GIT_SSH_KNOWN_HOSTS or GIT_SSH_NO_VERIFY_HOST inputs"
        exit 1
      else
        git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
      fi
    fi
else
    git config --global core.askPass /cred-helper.sh
    git config --global credential.helper cache
fi

git remote add mirror "${REMOTE}"
git config --global push.default current
git push ${GIT_PUSH_ARGS} mirror
git push --tags --force mirror
