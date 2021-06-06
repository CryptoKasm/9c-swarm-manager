#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh
# source ./scripts/graphql-queries.sh

# Checks containers for errors
function checkForErrors() {
  log info "  --checking for errors..."

  for ((i=1; i<=$MINERS; i++)); do
    argName="NAME_MINER_${i}"
    CONTAINERNAME=(${!argName})
    checkDocker=$(docker ps -aqf "name=$CONTAINERNAME")

    log trace "    --[checkForErrors] LOADING: $argName"
    log trace "    --[checkForErrors] CONTAINER_NAME: $CONTAINERNAME"
    log trace "    --[checkForErrors] CHECK_DOCKER: $checkDocker"

    if [[ $checkDocker ]]; then
      log debug "  --$CONTAINERNAME is running!"
    else
      log debug "  --$CONTAINERNAME is not running!"
    fi
    log debug "  --end loop"
  done
  log debug "  --end errorcheck"
}

# Check https://download.nine-chronicles.com/apv.json for changes
function checkForUpdates() {
    log info "  --checking for updates..."
    checkParams

    if [ wasUpdated == true ]; then
      log debug "     ----update installed"
      controlMiner --restart-all
    else
      log debug "     ----update not available"
    fi
}

# Auto restart miners after x hors
function autoRestart() {
  log info "  --checking for auto-restart..."

  for ((i=1; i<=$MINERS; i++)); do
    argName="NAME_MINER_${i}"
    CONTAINERNAME=(${!argName})

    setTimer=$((AUTO_RESTART * 3600))
    startTime=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINERNAME | xargs date +%s -d)
    currentTime=$(date +%s)
    timeLapsed=$((currentTime - startTime))

    log trace "    --[autoRestart] LOADING: $argName"
    log trace "    --[autoRestart] CONTAINER_NAME: $CONTAINERNAME"
    log trace "    --[autoRestart] AUTO_RESTART: $AUTO_RESTART hr = $setTimer sec"
    log trace "    --[autoRestart] START_TIME: $startTime"
    log trace "    --[autoRestart] CURRENT_TIME: $currentTime"
    log trace "    --[autoRestart] TIME_LAPSED: $timeLapsed"

    if [[ $timeLapsed -ge $setTimer ]]; then
      log debug "  --initiating restart for $CONTAINERNAME"
      controlMiner --restart $CONTAINERNAME
    else
      log debug "  --skipping restart for $CONTAINERNAME"
    fi
  done
}

# Live Logging
function liveLogging() {
  log info "[ LIVE-LOGGING - START ]"

  KILLTIME=5
  RUNTIME=15m

  case $MINER_LOG_FILTERS in

    ALL)
      LOGCMD="docker-compose -f $composeFile logs --tail=100 -f"
      ;;

    DEFAULT)
      LOGCMD="docker-compose -f $composeFile logs --tail=100 -f | grep --color -i -E 'Mined a block|reorged|mining|Append failed'"
      ;;

    MINIMAL)
      LOGCMD="docker-compose -f $composeFile logs --tail=20 | grep --color -i -E 'Mined a block|reorged|mining|Append failed'"
      ;;

    *)
      log error "[MINER_LOG_FILTERS] Argument is invalid. Please check correct syntax: $1"
      ;;

  esac
  
  timeout -k $KILLTIME $RUNTIME $LOGCMD

  log info "[ LIVE-LOGGING - CLOSED ]"
}

###############################
# Runs loop to keep-alive docker container
function keepAlive() {
    switchAlive=1
    tempVar=1
    
    while [ ${switchAlive} = 1 ]; do
        echo
        log info "[ KEEP-ALIVE ]"
        # checkForErrors
        checkForUpdates
        autoRestart

        sleep 15s

        liveLogging

        echo
    done
}
###############################
