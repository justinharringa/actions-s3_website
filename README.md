# GitHub Action / Docker container for s3_website
GitHub Action and [Docker container](https://hub.docker.com/r/justinharringa/s3_website/) 
to run [s3_website](https://github.com/laurilehmijoki/s3_website/)

## Docker Usage
This container has been published to Docker Hub and can be used as a container. To run it,
you'd run something like: 

```
docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY 
-e S3_BUCKET -e AWS_CLOUDFRONT_DISTRIBUTION --mount type=bind,source="$(pwd)",target=/site,readonly 
justinharringa/s3_website push --site _site
```

If you don't pass any arguments you'll see the equivalent of `s3_website help`. Note that you'll mount
your host location into `/site` and will also need to pass in any environment variables that your
`s3_website.yml` or `s3_website` itself requires.

[Docker Hub - justinharringa/s3_website](https://hub.docker.com/r/justinharringa/s3_website/)

## GitHub Actions Usage
The following example uses this GitHub Action to push the contents of the `build` folder to an 
S3 bucket and update a CloudFront distribution. It still requires that you provide an `s3_website.yml`
such as [s3_website.yml](/example/s3_website.yml).

```
workflow "Main" {
  on = "push"
  resolves = ["s3_website push"]
}

action "s3_website push" {
  uses = "justinharringa/actions-s3_website@master"
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "S3_BUCKET", "AWS_CLOUDFRONT_DISTRIBUTION"]
  args = "push --site build"
}
```

## Why?
I have been using s3_website for quite some time and it works great 
(huge thanks to [Lauri Lehmijoki](https://github.com/laurilehmijoki) / 
[Philippe Creux](https://github.com/pcreux)!!). I am giving GitHub Actions a shot and want to
use s3_website within a Docker container both in GitHub Actions and also for some other workflows
where I don't really want to have to worry about making sure the Java/Ruby bits are correct and
available. Thus far, this seems to work out quite well. Ideally, I'd like to contribute the Dockerfile
to [s3_website](https://github.com/laurilehmijoki/s3_website/).
