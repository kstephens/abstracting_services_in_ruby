#!/bin/sh
set -x
dir="$(cd "$(dirname $0)" && /bin/pwd)"
PATH="$dir/../bin:$PATH"
export RUBYLIB="$dir/../example:$dir/../lib"
asir="asir verbose=9 config_rb=$dir/config/asir_config.rb" 

# set -e
$asir start webrick worker
sleep 1
$asir pid webrick worker
if $asir alive webrick worker; then
  echo "alive"
fi

ruby "$dir/asir_control_client_http.rb"
sleep 1

$asir stop webrick worker
sleep 1
$asir pid webrick worker

$asir start zmq worker
sleep 1
$asir pid zmq worker
if $asir alive zmq worker; then
  echo "alive"
fi

ruby "$dir/asir_control_client_zmq.rb"
sleep 1

$asir stop zmq worker
sleep 1
$asir pid zmq worker

exit 0
