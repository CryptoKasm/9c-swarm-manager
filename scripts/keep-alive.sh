#!/bin/bash
# source ./scripts/log.sh
source ./scripts/lib.sh
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

    setAutoRestart=$((AUTO_RESTART * 3600))
    containerStartTime=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINERNAME | xargs date +%s -d)
    timeLapsed=$((currentTime - containerStartTime))

    log trace "    --[autoRestart] LOADING: $argName"
    log trace "    --[autoRestart] CONTAINER_NAME: $CONTAINERNAME"
    log trace "    --[autoRestart] AUTO_RESTART: $AUTO_RESTART hr = $setAutoRestart sec"
    log trace "    --[autoRestart] CONTAINER_START_TIME: $containerStartTime"
    log trace "    --[autoRestart] CURRENT_TIME: $currentTime"
    log trace "    --[autoRestart] TIME_LAPSED: $timeLapsed"

    if [[ $timeLapsed -ge $setAutoRestart ]]; then
      log debug "  --initiating restart for $CONTAINERNAME"
      controlMiner --restart $CONTAINERNAME
    else
      log debug "  --skipping restart for $CONTAINERNAME"
    fi
  done
}

# Auto clean miners after x hours
function autoClean() {
  log info "  --checking for auto-clean..."
  # Check start time of manager container
  # If current time is greater than x, stopd & clean containers
  CONTAINERNAME="manager"

  setAutoClean=$((AUTO_CLEAN * 3600))
  timeLapsed=$((currentTime - startTimer))
  
  log trace "    --[autoClean] LOADING: $argName"
  log trace "    --[autoClean] CONTAINER_NAME: $CONTAINERNAME"
  log trace "    --[autoClean] AUTO_CLEAN: $AUTO_RESTART hr = $setAutoClean sec"
  log trace "    --[autoClean] START_TIME: $startTimer"
  log trace "    --[autoClean] CURRENT_TIME: $currentTime"
  log trace "    --[autoClean] TIME_LAPSED: $timeLapsed"

  if [[ $timeLapsed -ge $setAutoClean ]]; then
    log debug "  --initiating auto-clean"
    controlMiner --down-all
    cleanDocker --dangling # Make this a config setting
    restartSwarmManager
  else
    log debug "  --skipping auto-clean"
  fi
}

# Live Logging
function liveLogging() {
  log info "[ LIVE-LOGGING - START ]"

  KILLTIME=5
  RUNTIME=15m

  case $MINER_LOG_FILTERS in

    ALL)
      CMD="docker-compose -f $composeFile logs --tail=100 -f"
      ;;

    DEFAULT)
      CMD="docker-compose -f $composeFile logs --tail=100 -f | grep --color -i -E 'Mined a block|reorged|mining|Append failed'"
      ;;

    MINIMAL)
      CMD="docker-compose -f $composeFile logs --tail=20 | grep --color -i -E 'Mined a block|reorged|mining|Append failed'"
      ;;

    *)
      log error "[MINER_LOG_FILTERS] Argument is invalid. Please check correct syntax: $1"
      ;;

  esac
  
  timeout -k $KILLTIME $RUNTIME $CMD

  log info "[ LIVE-LOGGING - CLOSED ]"
}

# Display container stats
function displayStats() {
  log info "[ LIVE-STATS ]"

  KILLTIME=5
  RUNTIME=15m
  CMD="docker stats --no-stream"
  $CMD
}

###############################
# Runs loop to keep-alive docker container
function keepAlive() {
    switchAlive=1
    tempVar=1
    startTimer=$(date +%s)

    while [ ${switchAlive} = 1 ]; do
        currentTime=$(date +%s)
        timeLapsed=0

        echo
        log info "[ KEEP-ALIVE ]"
        # checkForErrors
        checkForUpdates
        autoRestart
        autoClean
        echo
        displayStats
        
        log debug "--------------------------------"
        sleep 15m
    done
}
###############################
