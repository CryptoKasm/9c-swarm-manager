#!/bin/bash

# Init shutdown/restart commands for miners
function controlMiner {
  case $1 in

    --restart-all)
      docker-compose -f $composeFile stop
      docker-compose -f $composeFile start
      ;;

    --stop-all)
      docker-compose -f $composeFile stop
      ;;

    --down-all)
      compose-docker -f $composeFile down -v --remove-orphans
      ;;

    --restart)
      docker-compose -f $composeFile stop $2
      docker-compose -f $composeFile start $2
      ;;

    --stop)
      docker-compose -f $composeFile stop $2
      ;;

    --down)
      compose-docker -f $composeFile down -v --remove-orphans $2
      ;;

    *)
      log error "[controlMiner] Argument is invalid. Please check correct syntax: $i"
      ;;

  esac
}
