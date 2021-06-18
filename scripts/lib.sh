#!/bin/bash

#-----------------------------------------------------------
# Global Variables
#-----------------------------------------------------------

versionFile='./VERSION'
argsFile='.arguments'
composeFile='docker-compose.swarm.yml'
threadedImage='cryptokasm/ninechronicles-headless:v100050.T'

#-----------------------------------------------------------
# Terminal Style
#-----------------------------------------------------------

# Colors
Yellow="\e[33m"
Cyan="\e[36m"
Magenta="\e[35m"
Green="\e[92m"
Red="\e[31m"
RS="\e[0m"
RSL="\e[1A\e["
RSL2="\e[2A\e["
RSL3="\e[3A\e["
sB="\e[1m"

# Introduction
function intro() {
    echo
    log meta "> Nine Chronicles | Community Tool"
    log meta "  --Project: $project"
    log meta "  --Version: $version"
    log meta "  --Docker Repository: $docker"
    log meta "  --Github: $github"
    log meta "  --Maintainer: $maintainer"
    log meta "  --Discord/Support: $discord"
    echo
}

#-----------------------------------------------------------
# Useful Functions
#-----------------------------------------------------------

# Restart swarm-manager script from beginning
function restartSwarmManager() {
    ./swarm-manager.sh --start --keep-alive
}

# Check if user is root and grant permission if not
function checkRoot() { 
    if [ "$EUID" -ne 0 ]; then
        sudo echo -ne "\r"
    fi
}

# Set permissions for this project
function setPermissions() {
    log info "> Setting permissions for this project..."
    log debug "  --directory permissions"
    sudo find . -type d -exec chmod 770 {} \;

    log debug "  --file permission"
    sudo find . -type f -exec chmod 660 {} \;

    log debug "  --scripts as executable"
    sudo find . -name "*.sh" -exec chmod +x {} \;
}

# Adds new params to $argsFile or updates existing
# TODO_MODIFY: Convert to a reusable function with supplied variables [$selectARG, $newARG]
function updateParams() {
    source $argsFile

    log trace "    --checking if apv.json matches $argsFile"
    
    # AVP
    if [ ! $(grep -F "APV=" $argsFile) ]; then
        log trace "    --saving AVP"
            cat <<EOF >>$argsFile
APV=$newAPV
EOF
        source $argsFile
        log trace "    --newAPV: $APV"
    elif [[ $newAPV != $APV ]]; then
        log trace "    --updating APV"
        log trace "    --currentAPV: $APV"
        sed -i -e 's|APV=.*|APV='"$newAPV"'|' $argsFile
        source $argsFile
        log trace "    --newAPV: $APV"
        wasUpdated=true
    else
        log trace "    --[ARG] AVP is current"
    fi

    # DOCKER_IMAGE
    if [ ! $(grep -F "DOCKER_IMAGE=" $argsFile) ]; then
        log trace "    --saving DOCKER_IMAGE"
            cat <<EOF >>$argsFile
DOCKER_IMAGE=$newDOCKER_IMAGE
EOF
        source $argsFile
        log trace "    --newDOCKER_IMAGE: $DOCKER_IMAGE"
    elif [[ $newDOCKER_IMAGE != $DOCKER_IMAGE ]]; then
        log trace "  --updating DOCKER_IMAGE"
        log trace "    --currentDOCKER_IMAGE: $DOCKER_IMAGE"
        sed -i -e 's|DOCKER_IMAGE=.*|DOCKER_IMAGE='"$newDOCKER_IMAGE"'|' $argsFile
        source $argsFile
        log trace "    --newDOCKER_IMAGE: $DOCKER_IMAGE"
        wasUpdated=true
    else
        log trace "    --[ARG] BUILD_IMAGE is current"
    fi

    # SNAPSHOT
    if [ ! $(grep -F "SNAPSHOT=" $argsFile) ]; then
        log trace "    --saving SNAPSHOT"
            cat <<EOF >>$argsFile
SNAPSHOT=$newSNAPSHOT
EOF
        source $argsFile
        log trace "    --newSNAPSHOT: $SNAPSHOT"
    elif [[ $newSNAPSHOT != $SNAPSHOT ]]; then
        log trace "    --updating SNAPSHOT"
        log trace "    --currentSNAPSHOT: $SNAPSHOT"
        sed -i -e 's|SNAPSHOT=.*|SNAPSHOT='"$newSNAPSHOT"'|' $argsFile
        source $argsFile
        log trace "    --newSNAPSHOT: $SNAPSHOT"
        wasUpdated=true
    else
        log trace "    --[ARG] SNAPSHOT is current"
    fi

}

# Check parameters from https://download.nine-chronicles.com/apv.json
function checkParams() {

    # TODO_1: Curl query to variable
    # TODO_2: Pull matching strings into variables
    # TODO_3: Write params to .args
    # TODO_ADD_SUPPORT_FUNCTION: saveParams, updateParams
    # TODO_BUILD_OFF_THIS: add new update loop to keepAlive()

    log debug "  --loading PARAMS"

    BUILDPARAMSURL="https://download.nine-chronicles.com/apv.json?v=$RANDOM"
    newBUILDPARAMS=$(curl $BUILDPARAMSURL \
        -s \
        -L \
        -H "Cache-Control: no-cache, no-store, must-revalidate" \
        -H "Pragma: no-cache" \
        -H "Expires: 0")
    newAPV=$(echo $newBUILDPARAMS | jq -r '.apv')
    newDOCKER_IMAGE=$(echo $newBUILDPARAMS | jq -r '.docker')
    newSNAPSHOT=$(echo $newBUILDPARAMS | jq -r '.snapshotPaths[0]')

    # log trace "    --newURL: $newBUILDPARAMS"
    log trace "    --newAPV: $newAPV"
    log trace "    --newDockerImage: $newDOCKER_IMAGE"
    log trace "    --newSnapshotURL: $newSNAPSHOT"
    updateParams
    echo
}

# Check if "VERSION" exists and source
function checkVERSION() {
    log debug "  --loading VERSION"

    if [[ -f "$versionFile" ]]; then
        log trace "    --file found"
        source $versionFile

        # if [ "$TRACE" == "1" ]; then 
        #     cat $versionFile
        # fi
    else
        log warn "     --file not found"
    fi

}


# Check if "$argsFile" exists and source
function checkARGs() {
    log debug "  --loading ARGs"
    if [[ -f "$argsFile" ]]; then
        source $argsFile

        while IFS= read -r line; do
            log trace "    --[ARG] $line"
        done < $argsFile
    else
        log error "  --file not found"
    fi

}

# Save Dockerfile ARGs to $argsFile file
function saveARGs() {
    log info "> Saving runtime ARGS to file..."

    # TODO: 1. Set environment variables as lower case
    # TODO: 2. Compare with settings.conf, if env variable given is different add to args file
    if [[ "${private_key:-PUT_YOUR_PRIVATE_KEY_HERE}" == "PUT_YOUR_PRIVATE_KEY_HERE" ]]; then
        log error "[saveARGS] PRIVATE_KEY not set! Please set at docker runtime!"
        exitMain
    elif [[ "$private_key" == "disable" ]]; then
        disable_private_key="true"
    elif [[ "$private_key" == "demo" ]]; then
        log debug "  --Using Demo Account"
        private_key="10285a19fab2b4f7476efdaba07ed55e9b03790c4ff6f3fc7c6b2d0852a27fa2" 
    elif [[ ! "${#private_key}" -eq "64" ]]; then
        log error "[saveARGS] PRIVATE_KEY is invalid!"
        exitMain
    else 
        log debug "  --PRIVATE_KEY is valid"
    fi

    log trace "    --PRIVATE_KEY_LENGTH: ${#private_key}"

    if [ -f $argsFile ]; then
        rm -f $argsFile
        log trace "    --deleted old file"
    fi
    
    if [[ ${debug:-false} == true ]]; then 
        debug=1
        log trace "    --Debug Enabled: $debug"
    fi
    
    if [[ ${trace:-false} == true ]]; then 
        trace=1
        log trace "    --Trace Enabled: $trace"
    fi

    log trace "    --creating new file"
    cat <<EOF >$argsFile
DEBUG=${debug:-0}
TRACE=${trace:-0}
DEV_MODE=${dev_mode:-false}
DISABLE_MINING=${disable_mining:-false}
DISABLE_PRIVATE_KEY=${disable_private_key:-false}
PRIVATE_KEY=${private_key:-PUT_YOUR_PRIVATE_KEY_HERE}
MINERS=${miners:-1}
GRAPHQL_PORT=${graphql_port:-23070}
PEER_PORT=${peer_port:-31270}
RAM_LIMIT=${ram_limit:-4096M}
RAM_RESERVE=${ram_reserve:-2048M}
ENABLE_GRAPHQL_TOKEN=${enable_graphql_token:-false}
DISABLE_CORS=${disable_cors:-false}
AUTO_RESTART=${auto_restart:-0}
AUTO_CLEAN=${auto_clean:-0}
MINER_LOG_FILTERS=${miner_log_filters:-default}
USE_THREADED_IMAGE=${use_threaded_image:-false}
THREAD_COUNT=${thread_count:-1}
EOF

    if [ -f $argsFile ]; then
        log trace "    --file created successfully"
    else
        log error "    --unable to save to file: $argsFile"
    fi
}

# Apply default settings to arguments that werent given at runtime
# function checkDefault() {

# }

# Combines functions to perform a precheck on start
function preCheck() {
    log info "> Loading prerequisites..."
    
    saveARGs
    checkARGs
    checkVERSION
    checkParams
}

# Display logging from all deployed miners
function displayLogging() {
    log info "> Display miner logs with filters"
}
