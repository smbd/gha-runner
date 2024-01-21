#!/bin/bash

URL_OR_REPO="$1"
GH_PAT="$2"

function abort () {
  echo "$1" 1>&2
  exit 1
}

if echo ${URL_OR_REPO} | grep -q "^https:\/\/" ; then
  URL=${URL_OR_REPO}
else
  if echo ${URL_OR_REPO} | grep -q -P "[\w-]+/\w" ; then
    URL="https://github.com/${URL_OR_REPO}"
  else
    if echo ${URL_OR_REPO} | grep -q bash ; then
      exec /bin/bash
    else
      abort "\$1(${URL}) is not URL nor reponame"
    fi
  fi
fi

echo ${GH_PAT} | grep -q "^ghp_" || abort "\$2(${GH_PAT}) is not valid Github private access token"

cd /home/runner || abort "chdir failed"

./config.sh --unattended --ephemeral --name arm64-runner --url ${URL} --pat ${GH_PAT} | grep -q "A runner exists with the same name"
pipestatus=("${PIPESTATUS[@]}")
if [ ${pipestatus[0]} -ne 0 ] ; then
  if [ ${pipestatus[1]} -eq 0 ] ; then
    # restore relms
    if [ $(find relm -type f -size +1c -name 'dot.*' | wc -l) -eq 3 ] ; then
      for file in runner credentials credentials_rsaparams ; do
        rm -f .${file}
        ln -s relm/dot.${file} .${file} || abort "missind relm file: ${file}"
      done
    else
      abort "missing relm files, delete self-hosted runner from github.com WebUI"
    fi
  else
    abort "an error is occured, in config.sh"
  fi
else
  # save configs for next time
  for file in runner credentials credentials_rsaparams ; do
    cp .${file} relm/dot.${file}
  done
fi

./run.sh
