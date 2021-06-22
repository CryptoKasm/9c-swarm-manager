#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh
# checkARGs
# checkParams

# Set variables
SNAPDIR="latest-snapshot"
SNAPUNZIP="$SNAPDIR/9c-main"
SNAPZIP="state_latest.zip"
composeFile='docker-compose.swarm.yml'

# Copy snapshot to volumes
function copyVolume(){
    log info "> Copying snapshot to volumes..."
    
    cd $SNAPDIR    

    for ((i=1; i<=$MINERS; i++)); do
        argName="NAME_MINER_${i}"
        CONTAINERNAME=(${!argName})

        log debug "  --volume for $CONTAINERNAME"
        docker cp . $CONTAINERNAME:/app/data/
    done

    cd ..
}

# Check, download, extract snapshot partitions
function refreshSnapshotPartitions() {
        log info "> Updating snapshot partitions..."

        if [[ "$TRACE" == "1" ]]; then 
            log info "  --cleaning docker container"
            docker-compose -f $composeFile down -v --remove-orphans
            docker-compose -f $composeFile up -d
            docker-compose -f $composeFile stop
        else
            log info "  --cleaning docker container"
            {
            docker-compose -f $composeFile down -v --remove-orphans
            docker-compose -f $composeFile up -d
            docker-compose -f $composeFile stop
            } &> /dev/null
        fi

        baseUrl="https://snapshots.nine-chronicles.com/main/e7922c/partition/"
        filePath=$SNAPDIR
        latest="${baseUrl}latest.json"
        latestState="${baseUrl}state_latest.zip"

        log trace "    --baseURL: $baseUrl"
        log trace "    --filePath: $filePath"
        log trace "    --latest: $latest"
        log trace "    --latestState: $latestState"

        log debug "  --cleaning old zip files..."
        rm *.zip &> /dev/null

        log debug "  --checking if directory exists..."
        if [ -d $filePath ]; then
                log debug "  --cleaning directory: $filePath"
                rm -rf $filePath
        fi
        log debug "  --creating directory: $filePath"
        mkdir -p $filePath

        declare -A arrayBlockEpoch
        declare -A arrayTxEpoch
        declare -A arrayPreviousBlockEpoch
        declare -A arrayPreviousTxEpoch

        epoch=$(curl -s $latest \
                -s \
                -L \
                -H "Cache-Control: no-cache, no-store, must-revalidate" \
                -H "Pragma: no-cache" \
                -H "Expires: 0")
        arrayBlockEpoch[0]=$(echo $epoch | jq -r '.BlockEpoch')
        arrayTxEpoch[0]=$(echo $epoch | jq -r '.TxEpoch')
        arrayPreviousBlockEpoch[0]=$(echo $epoch | jq -r '.PreviousBlockEpoch')
        arrayPreviousTxEpoch[0]=$(echo $epoch | jq -r '.PreviousTxEpoch')

        log trace "    --epoch: $epoch"
        log trace "    --blockEpoch: ${arrayBlockEpoch[0]}"
        log trace "    --txEpoch: ${arrayTxEpoch[0]}"
        log trace "    --previousBlockEpoch: ${arrayPreviousBlockEpoch[0]}"
        log trace "    --previousTxEpoch: ${arrayPreviousTxEpoch[0]}"

        log debug "  --calculating total amount of snapshots to download..."

        lastEpoch=false
        i=0
        while [ ${lastEpoch} != true ]; do
                
                nextEpochMeta="${baseUrl}snapshot-${arrayPreviousBlockEpoch[${i}]}-${arrayPreviousTxEpoch[${i}]}.json"
                log trace "    --nextEpochMeta: $nextEpochMeta"
                ((i++))
                epoch=$(curl -s $nextEpochMeta \
                        -s \
                        -L \
                        -H "Cache-Control: no-cache, no-store, must-revalidate" \
                        -H "Pragma: no-cache" \
                        -H "Expires: 0")
                arrayBlockEpoch[${i}]=$(echo $epoch | jq -r '.BlockEpoch')
                arrayTxEpoch[${i}]=$(echo $epoch | jq -r '.TxEpoch')
                arrayPreviousBlockEpoch[${i}]=$(echo $epoch | jq -r '.PreviousBlockEpoch')
                arrayPreviousTxEpoch[${i}]=$(echo $epoch | jq -r '.PreviousTxEpoch')

                log trace "    --epoch: $epoch"
                log trace "    --blockEpoch: ${arrayBlockEpoch[${i}]}"
                log trace "    --txEpoch: ${arrayTxEpoch[${i}]}"
                log trace "    --previousBlockEpoch: ${arrayPreviousBlockEpoch[${i}]}"
                log trace "    --previousTxEpoch: ${arrayPreviousTxEpoch[${i}]}"

                if [ 0 -eq ${arrayPreviousBlockEpoch[${i}]} ]; then
                        log trace "    --previousBlockEpoch is 0"
                        lastEpoch=true
                fi
                
        done

        log debug "  --number of snapshot partitions to download: ${#arrayBlockEpoch[*]} "

        for ((i=0; i<${#arrayBlockEpoch[@]}; i++)); do
                filename="snapshot-${arrayBlockEpoch[${i}]}-${arrayTxEpoch[${i}]}.zip"
                log debug "  --downloading: $filename"
                nextSnapshot="${baseUrl}${filename}"
                curl -# $nextSnapshot -o $filename
                
                log trace "    --arrayBlockEpoch: ${arrayBlockEpoch[${i}]}"
                log trace "    --arrayTxEpoch: ${arrayTxEpoch[${i}]}"
                log trace "    --filename: ${filename}"
                log trace "    --nextSnapshot: ${nextSnapshot}"
        done

        filename="state_latest.zip"
        log debug "  --downloading latest_state.zip"
        curl -# $latestState -o $filename

        reverseOrder=$((${#arrayBlockEpoch[@]}-1))
        for ((i=$reverseOrder; i>=0; i--)); do
                filename="snapshot-${arrayBlockEpoch[${i}]}-${arrayTxEpoch[${i}]}.zip"
                log debug "  --extracting: $filename"
                nextSnapshot="${baseUrl}${filename}"
                unzip -o -q $filename -d $filePath
                
                log trace "    --arrayBlockEpoch: ${arrayBlockEpoch[${i}]}"
                log trace "    --arrayTxEpoch: ${arrayTxEpoch[${i}]}"
                log trace "    --filename: ${filename}"
                log trace "    --nextSnapshot: ${nextSnapshot}"
        done

        filename="state_latest.zip"
        log debug "  --extracting latest_state.zip"
        unzip -o -q $filename -d $filePath

        sudo chmod -R 700 $filePath

        copyVolume
}

# Refresh if volume is missing
testVol() {
    log info "> Checking volumes"

    # TODO Add function to hide if DEBUG is enabled
    docker-compose -f $composeFile up -d
    docker-compose -f $composeFile stop

    for OUTPUT in $(docker ps -aqf "name=^9c-swarm" --no-trunc); do
        
        containerName=$(docker ps -af "id=$OUTPUT" --format {{.Names}})
        detectVol=$(docker exec $containerName [ -d "/app/data/9c-main" ])
        detectVolID=$?

        if [[ $detectVolID = "1" ]]; then
            log debug "  --$containerName: volume is missing!"
            cd latest-snapshot
            copyVolume
        else
            log debug "  --$containerName: volume is current!"
        fi

        log trace "    --containerName: $containerName"
        log trace "    --detectVol: $detectVol"
        log trace "    --detectVolID $detectVolID"

    done
}

# Ignore Volume test if docker containers are running
testDockerRunning() {
    if [ ! "$(docker ps -qf "name=^9c-swarm")" ]; then
        log debug "  --containers are not running"
        testVol
    else
        log debug "  --containers are currently running"
    fi
}

# Refresh if older than 2 hrs
testAge() {
    if [ -d "$SNAPUNZIP" ] && [ -f "$SNAPZIP" ]; then
        log debug "  --snapshot was found"
        sudo chmod -R 700 $SNAPUNZIP
        if [[ $(find "state_latest.zip" -type f -mmin +60) ]]; then
            log debug "  --refreshing snapshot" 
            refreshSnapshotPartitions
        else
            log debug "  --snapshot is current"
            testDockerRunning
        fi
    else
        log debug "  --snapshot not found"
        refreshSnapshotPartitions
    fi
}

###############################
snapshot() {
    log info "> Checking for snapshot..."
    testAge
    echo
}
###############################