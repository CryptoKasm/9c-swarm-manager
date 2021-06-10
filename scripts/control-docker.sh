#!/bin/bash

# TODO Add if checks to make sure dangling is there or skip

# Init shutdown/restart commands for miners
function cleanDocker {
    case $1 in

        --dangling)
        # DELETE DANGLING CONTAINERS, VOLUMES, AND NETWORKS THAT ARE NOT USED BY CONTAINERS
        # docker rm $(docker ps -aqf status=exited)
        docker ps -qa --no-trunc --filter "status=exited" | xargs -r docker rm
        docker images -q -f dangling=true | xargs -r docker rmi
        docker volume ls -qf dangling=true | xargs -r docker volume rm
        #$(docker network ls | grep "bridge" | awk '/ / { print $1 }') | xargs -r docker network rm
        ;;

        --all-volumes)
        # DELETE ALL VOLUMES NOT USED BY CONTAINERS
        docker volume ls -q | xargs -r docker volume rm
        ;;

        --all)
        # DELETE STOPPED CONTAINERS, VOLUMES, AND NETWORKS THAT ARE NOT USED BY CONTAINERS
        docker system prune -af
        ;;

        *)
        log error "[cleanDocker] Argument is invalid. Please check correct syntax: $i"
        ;;

    esac
}

# Provides easy to use docker commands
function controlDocker() {
    case $1 in

        --kill-all)
        # KILL ALL RUNNING CONTAINERS
        docker kill $(docker ps -q)
        ;;

        *)
        log error "[controlDocker] Argument is invalid. Please check correct syntax: $i"
        ;;

    esac 
}