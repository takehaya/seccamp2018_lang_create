PROGRAM=./region_mio
LIBSRC=./lib.c

function compile {
  lib=$(mktemp -q /tmp/$(uuidgen).ll)
  clang -c -S -emit-llvm "$LIBSRC" -o "$lib"
  if [ "$?" != "0" ]; then
    echo -e "lib compile failed $1"
    exit 1
  fi

  ll=$(mktemp -q /tmp/$(uuidgen).ll)
  cat "$1" | gtimeout 5 "$PROGRAM" "$ll"
  if [ "$?" != "0" ]; then
    echo "ll compile failed $1"
    exit 1
  fi

  bc=$(mktemp -q /tmp/$(uuidgen).bc)
  /usr/local/Cellar/llvm/6.0.1/bin/llvm-link "$ll" "$lib" -S -o "$bc"
  if [ "$?" != "0" ]; then
    echo -e "bc compile failed $1"
    exit 1
  fi

  s=$(mktemp -q /tmp/$(uuidgen).s)
  /usr/local/Cellar/llvm/6.0.1/bin/llc "$bc" -o "$s"
  if [ "$?" != "0" ]; then
    echo -e "s compile failed $1"
    exit 1
  fi

  clang -no-pie "$s" -o "$2"
  if [ "$?" != "0" ]; then
    echo -e "compile failed $1"
    exit 1
  fi
}
function run {
  o=$(mktemp)
  compile $1 $o
  "$o"
}

case $1 in
  "run") run $2;;
  *) compile $@
esac

