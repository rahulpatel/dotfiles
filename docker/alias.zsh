#!/usr/bin/env zsh

function docker_nuke() {
  docker kill $(docker ps -q)
  docker system prune -a
}

alias docker-nuke="docker_nuke"
alias docker-space="docker system df"
