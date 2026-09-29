export LA_MANCHA_NODE=quijote

sdir() {
  echo $1
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

ddir() {
  echo $1
}

dget() {
  local out
  out=$(mktemp /tmp/dget.XXXXXX)
  scp -q dolce:"$1" "$out" && echo $out
}

dput() {
  scp -q "$1" dolce:"$2"
}

dmaster() {
  ssh -O check dolce >/dev/null 2>&1 && return
  ssh -N -f -o ControlMaster=yes -o ConnectTimeout=10 -o BatchMode=yes dolce \
    </dev/null >/dev/null 2>&1
}

dolce() {
  local out rc dir= secs=300 cmd
  out=$(mktemp /tmp/dolce.XXXXXX)
  dmaster
  while true; do
    case $1 in
      -C) dir=$(ddir $2); shift 2 ;;
      -t) secs=$2; shift 2 ;;
      *) break ;;
    esac
  done
  cmd="$*"
  local to=(); (( $+commands[gtimeout] )) && to=(gtimeout $secs)
  $to ssh -n -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
    -o BatchMode=yes dolce \
    "${dir:+cd ~/${(q)dir} && }zsh -lic ${(q)cmd}" > $out 2>&1
  rc=$?
  echo $out
  [[ $(wc -l < $out) -le 50 ]] && cat $out
  return $rc
}

azor() {
  local to=${1#@}; shift
  local sess=${to%%@*} node=${to#*@} f=${from:-azor}
  [[ $f != *@* && -n $LA_MANCHA_NODE ]] && f=$f@$LA_MANCHA_NODE
  if [[ $to == *@* && $node != $LA_MANCHA_NODE ]]; then
    typeset -f $node > /dev/null || { echo "azor: no reach to $node"; return 1; }
    $node "from=$f azor @$sess $*"
    return
  fi
  claude -p --agent azor --model haiku --name "$f" \
    "deliver to $sess: $*"
}

[[ -n $LA_MANCHA_LOCAL && -f $LA_MANCHA_LOCAL ]] && source $LA_MANCHA_LOCAL
