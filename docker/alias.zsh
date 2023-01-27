#!/usr/bin/env zsh

function docker-nuke() {
  docker kill $(docker ps -q)
  docker system prune -a
}

alias docker="podman"
alias docker-nuke="docker-nuke"
alias docker-space="docker system df"
