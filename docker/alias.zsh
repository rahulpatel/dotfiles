function nuke-docker {
  docker stop $(docker ps -aq)
  docker system prune -a
}

alias nuke-docker="nuke-docker"
