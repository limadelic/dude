windmill() {
  local twin dir send a
  [ "$(scutil --get LocalHostName)" = "$quijote" ] && twin=sancho || twin=quijote
  dir=$(git remote get-url $twin) || return 1
  [ "$1" = "$twin" ] && { send=1; shift; }

  for a in "$@"; do
    if [ "$send" ]; then
      rsync -avR "$a" "$dir/"
    else
      rsync -avR "$dir/./$a" .
    fi
  done
}

sancho() {
  local out rc
  out=$(mktemp /tmp/sancho.XXXXXX)
  ssh sancho "security unlock-keychain -p '$sancho' 2>/dev/null; zsh -lic '$@'" > $out 2>&1
  rc=$?
  echo $out
  return $rc
}
