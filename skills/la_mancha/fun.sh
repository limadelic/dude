sdir() {
  echo $1
}

qdir() {
  local p=$(sdir $1) root=${LA_MANCHA_ROOT:-$HOME}
  echo $root/${p#dev/}
}

xfer() {
  rsync -az \
    --exclude .git --exclude node_modules --exclude obj --exclude bin \
    --exclude .idea --exclude .DS_Store --exclude coverage --exclude dist \
    "$@"
}

spull() {
  local p=$(sdir $1) l=$(qdir $1)
  if [[ -d $l || $1 != */*.* ]]; then
    mkdir -p $l
    xfer --delete sancho:$p/ $l/
  else
    mkdir -p ${l%/*}
    xfer sancho:$p $l
  fi
  echo $l
}

windmill() {
  local p=$(sdir $1) l=$(qdir $1) parent
  if [[ -d $l ]]; then
    parent=$p
    xfer --rsync-path="mkdir -p ~/$parent && rsync" $l/ sancho:$p/
  else
    parent=${p%/*}
    xfer --rsync-path="mkdir -p ~/$parent && rsync" $l sancho:$p
  fi
  echo sancho:$p
}

sget() {
  local out
  out=$(mktemp /tmp/sget.XXXXXX)
  scp -q sancho:"$1" "$out" && echo $out
}

sput() {
  scp -q "$1" sancho:"$2"
}

smaster() {
  ssh -O check sancho >/dev/null 2>&1 && return
  ssh -N -f -o ControlMaster=yes -o ConnectTimeout=10 -o BatchMode=yes sancho \
    </dev/null >/dev/null 2>&1
}

sancho() {
  local out rc dir= secs=300 cmd
  out=$(mktemp /tmp/sancho.XXXXXX)
  smaster
  while true; do
    case $1 in
      -C) dir=$(sdir $2); shift 2 ;;
      -t) secs=$2; shift 2 ;;
      *) break ;;
    esac
  done
  cmd="$*"
  local to=(); (( $+commands[gtimeout] )) && to=(gtimeout $secs)
  $to ssh -n -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
    -o BatchMode=yes sancho \
    "security unlock-keychain -p ${(q)sancho} 2>/dev/null; ${dir:+cd ~/${(q)dir} && }zsh -lic ${(q)cmd}" > $out 2>&1
  rc=$?
  echo $out
  [[ $(wc -l < $out) -le 50 ]] && cat $out
  return $rc
}

[[ -n $LA_MANCHA_LOCAL && -f $LA_MANCHA_LOCAL ]] && source $LA_MANCHA_LOCAL
