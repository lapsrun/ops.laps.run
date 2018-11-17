#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

set -x

process_file(){
  local source="$1"

  # build start
  local before_install=$(yq r "$source" timing.before_install.start)

  # deploy-preview start
  local after_success=$(yq r "$source" timing.after_success.start)

  # deploy-production start
  local before_deploy=$(yq r "$source" timing.before_deploy.start)

  local date=$before_install
  date=${date/null/$after_success}
  date=${date/null/$before_deploy}

  yq w -i "$source" date "$date"

  local source_without_ext=${source%.yml}
  local source_basename=$(basename $source_without_ext)

  yq w -i "$source" title "$source_basename"

  local source_md="$source_without_ext.md"
  local destination=${source_md/data-editable/content}

  mkdir -p "$(dirname $destination)"

  echo "---" > "$destination"
  cat "$source" >> "$destination"
  echo "---" >> "$destination"
}
export -f process_file

main(){
  aws s3 sync s3://laps.run-ops-data-private/ data/
  cp -R data data-editable

  find data-editable -name "*.yml" -exec bash -c 'process_file "$@"' bash {} \;

  HUGO_ENV=production hugo

  sed -i -e "s/123456abcdef/${TRAVIS_COMMIT:-234567bcdefg}/g" public/index.html
}

main
