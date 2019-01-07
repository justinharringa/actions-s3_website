# actions-s3_website
GitHub Action to run s3_website (https://github.com/laurilehmijoki/s3_website/)

## Docker Usage
This container has been published to Docker Hub and can be used as a container. To run it,
simply run `docker run --rm justinharringa/s3_website ...` where `...` is the normal arguments
you'd pass to s3_website. If you don't pass any arguments you'll see the equivalent of 
`s3_website help`.

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
