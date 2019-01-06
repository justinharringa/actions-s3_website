workflow "Main" {
  on = "push"
  resolves = "Docker Push"
}

action "Docker Lint" {
  uses = "docker://replicated/dockerfilelint"
  args = ["Dockerfile"]
}

action "Filter Master" {
  needs = ["Docker Lint"]
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Docker Build" {
  needs = "Filter Master"
  uses = "actions/docker/cli@master"
  args = "build -t s3_website ."
}

action "Docker Tag" {
  needs = "Docker Build"
  uses = "actions/docker/tag@master"
  args = "s3_website justinharringa/s3_website"
}

action "Docker Login" {
  needs = "Docker Build"
  uses = "actions/docker/login@master"
  secrets = ["DOCKER_USERNAME", "DOCKER_PASSWORD"]
}

action "Docker Push" {
  needs = ["Docker Tag", "Docker Login"]
  uses = "actions/docker/cli@master"
  args = "push justinharringa/s3_website"
}
