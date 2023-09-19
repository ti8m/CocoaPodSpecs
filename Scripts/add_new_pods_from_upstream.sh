#!/usr/bin/env bash

CSV_FILE=$1

ME=$(basename "$0")
BASE_FOLDER=$(cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)

DEPENDS="git md5sum"


die() {
  if [[ "$*" && -t 2 ]]; then
    printf "\e[31;1m%s\e[0m\n" "$*" >&2
  else
    printf "%s\n" "$*" >&2
  fi
  exit 1
}

usage() {
  cat <<-EOM
								Usage: $ME <podList>

								Example: $ME podList.csv

								Example podList.csv:

								name,version
								lottie-ios,4.1.3
								FirebaseCore,10.4.0
								...
				EOM
  exit 1
}

for CMD in $DEPENDS; do
  command -v "$CMD" >/dev/null 2>&1 || die "This script requires $CMD but it's not installed. Aborting."
done

[[ ${CSV_FILE} ]] || usage

REMOTE_NAME=$(git remote --verbose | grep 'https://github.com/CocoaPods/Specs (fetch)' | cut -f 1)
if [[ -z $REMOTE_NAME ]]; then
  REMOTE_NAME="upstream"
  git remote add "$REMOTE_NAME" https://github.com/CocoaPods/Specs
fi

git fetch "$REMOTE_NAME" --depth=1

# Read the csv-file but skip the header, ignore trailing newilne
tail -n +2 "${CSV_FILE}" |
  while IFS=',' read -r NAME VERSION || [ -n "${NAME}" ]; do
    HASH_VALUE=$(echo -n "$NAME" | md5sum)
    POD_DIRECTORY="Specs/${HASH_VALUE:0:1}/${HASH_VALUE:1:1}/${HASH_VALUE:2:1}/$NAME/$VERSION"
    echo "Fetch pod specs for $NAME with hash [$HASH_VALUE] from upstream into: $POD_DIRECTORY"
    ls "$POD_DIRECTORY" >/dev/null 2>&1 || {
      echo "Checking out $POD_DIRECTORY from $REMOTE_NAME/master"
      git checkout "$REMOTE_NAME"/master "$POD_DIRECTORY" ||
        die "An error occurred while checking out the specified pod"
    }
  done
