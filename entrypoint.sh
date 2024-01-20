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

# restore config after second time
if [ $(find relm -type f -size +1c -name 'dot.*' | wc -l) -eq 3 ] ; then
  for file in runner credentials credentials_rsaparams ; do
    ln -s relm/dot.${file} .${file}
  done
else
  # 1st time
  ./config.sh --unattended --name arm64-runner --url ${URL} --pat ${GH_PAT} || abort "config failed"

  # save configs for next time
  for file in runner credentials credentials_rsaparams ; do
    cp .${file} relm/dot.${file}
  done
fi

./run.sh
