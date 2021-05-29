#!/bin/bash
source ./VERSION
source ./scripts/log.sh
source ./scripts/lib.sh
source ./scripts/name-generator.sh
source ./scripts/docker-compose.sh
source ./scripts/snapshot.sh
source ./scripts/keep-alive.sh
source ./scripts/control-miners.sh

# Exit main script
function exitMain() {
  exit 1
}

# Clean up generated files
function clean() {
    log debug "> Cleaning generated files..."

    log debug "  --clean: $composeFile"
    sudo rm -f $composeFile
    log debug "  --clean: latest-snapshot"
    sudo rm -rf latest-snapshot
    log debug "  --clean: 9c-main-snapshot.zip"
    sudo rm -f 9c-main-snapshot.zip
    log debug "  --clean: logs"
    sudo rm -rf logs
    log debug "  --clean: vault"
    sudo rm -rf vault
}

# Clean up generated files
function cleanAll() {
    log debug "> Cleaning generated files..."

    log debug "  --clean: $composeFile"
    sudo rm -f $composeFile
    log debug "  --clean: latest-snapshot"
    sudo rm -rf latest-snapshot
    log debug "  --clean: 9c-main-snapshot.zip"
    sudo rm -f 9c-main-snapshot.zip
    log debug "  --clean: logs"
    sudo rm -rf logs
    log debug "  --clean: vault"
    sudo rm -rf vault
    log debug "  --clean: docker-orphans"
    docker-compose -f $composeFile down -v --remove-orphans
}

# Start docker container in detached mode
function startDocker() {
    log info "> Starting docker..."
    
    log trace "$(pwd)"
    
    if [ "$TRACE" == "1" ]; then 
        cat ./docker-compose.swarm.yml
    fi

    docker-compose -f ./docker-compose.swarm.yml up -d \
      && log debug "  --started" \
      || log error "${prev_cmd}";

    # docker-compose -f ./docker-compose.swarm.yml stop 
}

# Build docker image using data from VERSION file
function buildDockerImage() {
    imageName="$docker:$version"
    dockerFile="./Dockerfile"

    clean
    intro
    
    log info "> Building docker image: $imageName"
    docker build -f $dockerFile -t $imageName .

    log debug "  --Docker Image Name: $imageName"
    log debug "  --DockerFile Location: $dockerFile"
}

# Run docker image with parameters
function runDockerImage() {
    imageName="$docker:$version"

    log info "> Running docker image: $imageName"
    docker run -d -v "/var/run/docker.sock:/var/run/docker.sock" \
    --env TRACE=1 \
    --env DEV_MODE=true \
    --name 9c-swarm-manager $imageName
}

# Test dockerfile
function testDockerfile() {
    title "> DockerFile Testing"
    log debug "  --[Dockerfile]: ENV DEBUG=$DEBUG"
    log debug "  --[Dockerfile]: ENV PRIVATE_KEY=$PRIVATE_KEY"
    log debug "  --[Dockerfile]: ENV MINERS=$MINERS"
    log debug "  --[Dockerfile]: ENV GRAPHQL_PORT=$GRAPHQL_PORT"
    log debug "  --[Dockerfile]: ENV PEER_PORT=$PEER_PORT"
    log debug "  --[Dockerfile]: ENV RAM_LIMIT=$RAM_LIMIT"
    log debug "  --[Dockerfile]: ENV RAM_RESERVE=$RAM_RESERVE"
    log debug "  --[Dockerfile]: ENV AUTHORIZE_GRAPHQL=$AUTHORIZE_GRAPHQL"
    log debug "  --[Dockerfile]: ENV AUTO_RESTART=$AUTO_RESTART"
}

###############################
function swarmManager() {   
    intro
    preCheck
    nameGenerator
    dockerCompose
    snapshot
    startDocker
}
###############################
for i in "$@"; do
case $i in

  --clean)
    clean
    exit 0
    ;;

  --clean-all)
    cleanAll
    exit 0
    ;;

  --set-permissions)
    setPermissions
    exit 0
    ;;

  --force-refresh)
    forceRefresh
    exit 0
    ;;

  --check-volume)
    testVol
    exit 0
    ;;

  --running)
    testDockerRunning
    exit 0
    ;;

  --magic)
    docker-compose -f docker-compose.yml down -v --remove-orphans
    buildDockerImage
    runDockerImage
    exit 0
    ;;
    
  --build)
    buildDockerImage
    exit 0
    ;;
    
  --run)
    runDockerImage 
    exit 0
    ;;
    
  --start)
    swarmManager
    ;;

  --testDockerfile)
    testDockerfile
    ;;

  --persist)
    saveARGs
    ;;
  
  --wait)
    ./scripts/wait-for-it.sh "kibana:5601" --timeout=30
    ;;

  --monitor)
    sleep 30
    docker-compose -f $composeFile logs --tail=100 -f
    ;;
  
  --keep-alive)
    keepAlive
    ;;

  *)
    log error "[swarmManager.sh] Argument is invalid. Please check correct syntax: $i"
    exit 0
    ;;

esac
done

exit 0