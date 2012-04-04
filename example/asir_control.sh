#!/bin/sh
set -x
dir="$(cd "$(dirname $0)" && /bin/pwd)"
PATH="$dir/../bin:$PATH"
export RUBYLIB="$dir/../example:$dir/../lib"
asir="asir verbose=9 config_rb=$dir/config/asir_config.rb" 

# set -e
$asir start webrick worker
sleep 1

ruby "$dir/asir_control_client_http.rb"
sleep 1

$asir stop webrick worker
sleep 1

$asir start zmq worker
sleep 1

ruby "$dir/asir_control_client_zmq.rb"
sleep 1

exit 0
