alias docker-nuke="docker stop $(docker ps -a -q) && docker system prune -a"
