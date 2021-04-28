#!/bin/bash

# Init shutdown/restart commands for miners
function controlMiner {
  case $1 in

    --restart-all)
      docker-compose -f $composeFile stop
      docker-compose -f $composeFile start -d
      ;;

    --stop-all)
      docker-compose -f $composeFile stop
      exit 0
      ;;

    --down-all)
      compose-docker -f $composeFile down -v --remove-orphans
      exit 0
      ;;

    --restart)
      docker-compose -f $composeFile stop $2
      docker-compose -f $composeFile start -d $2
      exit 0
      ;;

    --stop)
      docker-compose -f $composeFile stop $2
      exit 0
      ;;

    --down)
      compose-docker -f $composeFile down -v --remove-orphans $2
      exit 0
      ;;

    *)
      log error "[controlMiner] Argument is invalid. Please check correct syntax: $i"
      exit 0
      ;;

  esac
}
