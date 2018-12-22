nuke-docker () {
  local images=$(docker ps -a -q)

  for image in $images; do
    docker stop $image
  done

  docker system prune -a
}

alias nuke-docker="nuke-docker"
