alias nuke-terraform-state="terraform state list | cut -f 1 -d '[' | xargs -L 0 terraform state rm"
