sun.major_version() {
  local versions="$1"
  IFS='.' read -ra versions <<< "$versions"
  echo "${versions[0]}.$(echo ${versions[1]} | sed -r 's/^([0-9]+).*/\1/')"
}

sun.manifest_path() {
  echo "$HOME/<%= @sun.MANIFEST_DIR %>/$1.log"
}
