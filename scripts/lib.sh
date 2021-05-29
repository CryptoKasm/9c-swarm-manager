#!/bin/bash

#-----------------------------------------------------------
# Global Variables
#-----------------------------------------------------------

versionFile='./VERSION'
argsFile='.args'

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

    log trace "    --newURL: $newBUILDPARAMS"
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

    if [ "$DEV_MODE" == true ]; then 
        log debug "  --Developer Mode: Enabled"

        if [[ "$PRIVATE_KEY" == "DISABLE" ]]; then
            DISABLE_PRIVATE_KEY="true"
            USE_DEMO_KEY="false"
        elif [[ "$PRIVATE_KEY" == "DEMO" ]]; then
            USE_DEMO_KEY="true"
        else
            USE_DEMO_KEY="false"
        fi
        DISABLE_MINING="true"
        DISABLE_CORS="true"
        GRAPHQL_PORT="23075"
        PEER_PORT="31275"

        log trace "    --Dev Override: [DISABLE_PRIVATE_KEY=$DISABLE_PRIVATE_KEY]"
        log trace "    --Dev Override: [USE_DEMO_KEY=$USE_DEMO_KEY]"
        log trace "    --Dev Override: [DISABLE_MINING=$DISABLE_MINING]"
        log trace "    --Dev Override: [DISABLE_CORS=$DISABLE_CORS]"
        log trace "    --Dev Override: [GRAPHQL_PORT=$GRAPHQL_PORT]"
        log trace "    --Dev Override: [PEER_PORT=$PEER_PORT]"
    fi

    if [[ "$USE_DEMO_KEY" == true ]]; then
        log debug "  --Using Demo Account"
        PRIVATE_KEY="10285a19fab2b4f7476efdaba07ed55e9b03790c4ff6f3fc7c6b2d0852a27fa2" 
    elif [[ "$PRIVATE_KEY" == "PUT_YOUR_PRIVATE_KEY_HERE" ]]; then
        log error "[saveARGS] PRIVATE_KEY not set! Please set at docker runtime!"
        exitMain
    fi

    if [ -f $argsFile ]; then
        rm -f $argsFile
        log trace "    --deleted old file"
    fi

    log trace "    --creating new file"
    cat <<EOF >$argsFile
DEBUG=$DEBUG
TRACE=$TRACE
DEV_MODE=$DEV_MODE
DISABLE_MINING=$DISABLE_MINING
DISABLE_PRIVATE_KEY=$DISABLE_PRIVATE_KEY
PRIVATE_KEY=$PRIVATE_KEY
MINERS=$MINERS
GRAPHQL_PORT=$GRAPHQL_PORT
PEER_PORT=$PEER_PORT
RAM_LIMIT=$RAM_LIMIT
RAM_RESERVE=$RAM_RESERVE
AUTHORIZE_GRAPHQL=$AUTHORIZE_GRAPHQL
DISABLE_CORS=$DISABLE_CORS
AUTO_RESTART=$AUTO_RESTART
MINER_LOG_FILTERS=$MINER_LOG_FILTERS
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
