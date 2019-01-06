# actions-s3_website
GitHub Action to run s3_website (https://github.com/laurilehmijoki/s3_website/)

## Docker Usage
This container has been published to Docker Hub and can be used as a container. To run it,
simply run `docker run --rm justinharringa/s3_website ...` where `...` is the normal arguments
you'd pass to s3_website. If you don't pass any arguments you'll see the equivalent of 
`s3_website help`.

## GitHub Actions Usage
Example GitHub Action:

```
workflow "Main" {
  on = "push"
  resolves = ["s3_website"]
}

action "s3_website" {
  uses = "docker://justinharringa/actions-s3_website:master"
  args = ["push", "and", "your", "args"]
}
```
