#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh
# checkARGs

# Saves picked names to variables in $argsFile file
function saveName() {
    log debug "    ----writing to $argsFile"
    
    cat <<EOF >>$argsFile
NAME_MINER_${1}=$2
EOF

    source $argsFile
}

# Test if $randomName has already been used by another container
function checkRandomName() {
    availARGs=false
    availDocker=false
    
    log debug "    ----availARGs: $availARGs"
    log debug "    ----availDocker: $availDocker"

    if [ ! "$(grep -F "$1" $argsFile)" ]; then
        log debug "    ----$1 is available for $argsFile"
        availARGs=true
    else
        log debug "    ----$1 is used in $argsFile"
    fi

    if [ ! "$(docker ps -aqf "name=^$1" --no-trunc)" ]; then
        log debug "    ----$1 is available for container"
        availDocker=true
    else
        log debug "    ----$1 is used by container"
    fi

    log debug "    ----availARGs: $availARGs"
    log debug "    ----availDocker: $availDocker"

    if [[ ${availARGs} = true && ${availDocker} = true ]]; then
        log debug "    ----$1 is available for all"
        nameAvailable=true
    else
        log debug "    ----retrying for new name"
    fi
}

# Picks a random name from a list to use as $CONTAINER_NAME
function pickRandomName() {
    nameAvailable=false
    tempRun=1

    while [ ${nameAvailable} != true ]; do
        log info "  --generating container_name"

        tempPlus=$((tempRun++))
        log debug "    ----run: $tempPlus"

        minerNames=("reaper" "jackal" "manta" "ferno" "scythe" "buster" "grym" "xerox" "spyte" "sliver" "raijin" "cypher" "sabre" "nuke" "komodo" "viger" "rackas" "visus" "blits" "bruizer" "asvin" "guillo" "ibis" "carkas" "blade" "quake" )
        
        randomName=${minerNames[$RANDOM % ${#minerNames[@]}]}
        log debug "    ----result: $randomName"

        checkRandomName $randomName 

        

        if [[ $tempPlus -ge 12 ]]; then
          nameAvailable=true
        fi
    done

    saveName="${randomName}"
    log debug "    ----saveName: $saveName"
}

# Checks if variable already exists and use if not empty
function checkARGsExists() {
    argExists=false
    argEmpty=true
    argPreset=false

    log debug "  --check if $argName exists in $argsFile"

    if [ "$(grep -F "$argName" $argsFile)" ]; then
        log trace "    --found in $argsFile"
        argExists=true

        if [[ ! -z "${!argName}" ]]; then
            log trace "    --not empty: ${!argName}"
            argEmpty=false
        else
            log trace "    --empty"
        fi
    else
        log trace "    --doesnt exist in $argsFile"
    fi

    if [[ ${argExists} = false && ${argEmpty} = true ]]; then
        log trace "    --ready to use"
        argAvailable=true
    elif [[ ${argExists} = true && ${argEmpty} = true ]]; then
        log trace "    --cleaning empty arg"
        sed -i "/$argName.*/d" $argsFile
        log trace "    --ready to use"
    elif [[ ${argExists} = true && ${argEmpty} = false ]]; then
        log trace "    --using preset name"
        argPreset=true
    fi
}

# Clean names from $argsFile
function cleanNames() {
    log debug " --cleaning names from $argsFile"
    sed -i "/NAME_MINER.*/d" $argsFile
}

###############################
function nameGenerator() {
    log info "> Generating names for miners..."
    
    for ((i=1; i<=$MINERS; i++)); do
        argName=("NAME_MINER_${i}")
        
        checkARGsExists $i

        if [ $argPreset != true ]; then
            pickRandomName $i
            saveName $i $saveName
        fi
    done
    echo
}
###############################