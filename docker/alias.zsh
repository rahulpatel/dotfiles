function docker-nuke() {
  docker kill $(docker ps -q)
  docker system prune -a
}
alias docker-nuke="docker-nuke"

alias docker-space="docker system df"
