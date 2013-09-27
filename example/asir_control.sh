#!/bin/sh
set -x
dir="$(cd "$(dirname $0)" && /bin/pwd)"
PATH="$dir/../bin:$PATH"
export RUBYLIB="$dir/../example:$dir/../lib"
asir="asir config_rb=$dir/config/asir_config.rb"
# asir="$asir verbose=9"
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

log_file="$($asir log webrick worker)"
echo log_file="$log_file"
cat $log_file
;;
esac

#############################

exit 0
