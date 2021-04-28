#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh

# Check https://download.nine-chronicles.com/apv.json for changes
function checkForUpdate() {
    log info "  --checking for update..."
    checkParams

    if [ wasUpdated == true ]; then
      log debug "     ----update installed"
      controlMiner --restart-all
    else
      log debug "     ----update not available"
    fi
}

###############################
# Runs loop to keep-alive docker container
function keepAlive() {
    switchAlive=1
    tempVar=1
    

    while [ ${switchAlive} = 1 ]; do
        log info "[ KEEP-ALIVE ]"

        log info "> Refreshing! Ding $((tempVar++))"
        
        
        checkForUpdate

        log debug "  --display miner stats"
        docker stats --no-stream

        sleep 1m


        # TODO Add timer to auto restart miners after x hours, spread out in 15min increments
    done
}
###############################
