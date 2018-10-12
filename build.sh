#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

set -x

process_file(){
  local source="$1"

  local source_md="${source%.yml}.md"
  local destination=${source_md/data/content}

  mkdir -p "$(dirname $destination)"

  echo "---" > "$destination"
  cat "$source" >> "$destination"
  echo "---" >> "$destination"
}
export -f process_file

main(){
  aws --profile personal s3 sync s3://laps.run-ops-data-private/ data/

  find data -name "*.yml" -exec bash -c 'process_file "$@"' bash {} \;

  HUGO_ENV=production hugo

  sed -i -e "s/123456abcdef/${TRAVIS_COMMIT:-234567bcdefg}/" public/index.html
}

main
