#!/bin/bash
# source ./scripts/log.sh
# source ./scripts/lib.sh
# checkARGs

# Set: Variables
SNAPDIR="latest-snapshot"
SNAPUNZIP="$SNAPDIR/9c-main"
SNAPZIP="9c-main-snapshot.zip"
composeFile='docker-compose.swarm.yml'

# Copy: Snapshot to Volumes
copyVolume(){
    log info "> Copying snapshot to volumes..."

    for ((i=1; i<=$MINERS; i++)); do
        argName="NAME_MINER_${i}"
        CONTAINERNAME=(${!argName})

        log debug "  --volume for $CONTAINERNAME"
        sudo docker cp . $CONTAINERNAME:/app/data/
    done

    cd ..
}

# Refresh: Snapshot
# TODO_MODIFY: Add sample snapshot for development
refreshSnapshot() {
    log info "> Refreshing snapshot..."
    log trace "    --SNAPDIR: $SNAPDIR"
    log trace "    --SNAPUNZIP: $SNAPUNZIP"
    log trace "    --SNAPZIP: $SNAPZIP"

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

    if [ -d $SNAPUNZIP ]; then
        log debug "  --clean: $SNAPDIR"
        rm -rf latest-snapshot/* 

        if [ -f "$SNAPZIP" ]; then
            log debug "  --clean: $SNAPZIP"
            rm -f $SNAPZIP
        fi
    else
        log debug "  --create dir: latest-snapshot"
        mkdir -p latest-snapshot
    fi

    cd latest-snapshot
    
    log debug "  --downloading snapshot (can take up to ~ 10mins)"
    curl -# -O $SNAPSHOT

    log debug "  --unzipping snapshot"
    unzip 9c-main-snapshot.zip &> /dev/null
    sudo chmod -R 700 .
    mv 9c-main-snapshot.zip ../

    copyVolume
}

# Test: Refresh if volume is missing
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

# Test: Ignore Volume test if docker containers are running
testDockerRunning() {
    if [ ! "$(docker ps -qf "name=^9c-swarm")" ]; then
        log debug "  --containers are not running"
        testVol
    else
        log debug "  --containers are currently running"
    fi
}

# Test: Refresh if older than 2 hrs
testAge() {
    if [ -d "$SNAPUNZIP" ] && [ -f "$SNAPZIP" ]; then
        log debug "  --snapshot was found"
        sudo chmod -R 700 $SNAPUNZIP
        if [[ $(find "9c-main-snapshot.zip" -type f -mmin +60) ]]; then
            log debug "  --refreshing snapshot" 
            refreshSnapshot
        else
            log debug "  --snapshot is current"
            testDockerRunning
        fi
    else
        log debug "  --snapshot not found"
        refreshSnapshot
    fi
}

###############################
snapshot() {
    log info "> Checking for snapshot..."
    testAge
    echo
}
###############################