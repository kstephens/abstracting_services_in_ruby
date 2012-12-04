#!/bin/sh
set -x
dir="$(cd "$(dirname $0)" && /bin/pwd)"
PATH="$dir/../bin:$PATH"
export RUBYLIB="$dir/../example:$dir/../lib"
asir="asir verbose=9 config_rb=$dir/config/asir_config.rb" 
args="$*"
args="${args:-ALL}"
# set -e

#############################

case "$args"
in
  *webrick*|*ALL*)

$asir start webrick worker
sleep 1
$asir pid webrick worker
if $asir alive webrick worker; then
  echo "alive webrick worker"
fi

ruby "$dir/asir_control_client_http.rb"
sleep 1

$asir stop webrick worker
sleep 1
$asir pid webrick worker

;;
esac

#############################

exit 0
