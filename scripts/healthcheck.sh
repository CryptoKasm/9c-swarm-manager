#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh

function checkPing() {
    log info "  --checking ping..."
    
    curl -f http://localhost/ || log error "${prev_cmd}";
}

function checkSwarm() {
    log info "  --checking swarm..."
}

###############################
function healthcheck() {
    log info "> HEALTHCHECK"
}
###############################
for i in "$@"
do
case $i in

  --check-ping)
    checkPing
    exit 0
    ;;

  --check-logging)
    checkLogging
    exit 0
    ;;

  --check-swarm)
    checkSwarm
    exit 0
    ;;

  --check-all)
    checkPing
    checkLogging
    checkSwarm
    exit 0
    ;;

esac
done

exit 0