FROM ruby:2.7.1

LABEL version="3.4.0"
LABEL repository="http://github.com/justinharringa/actions-s3_website"
LABEL homepage="http://github.com/justinharringa/actions-s3_website"
LABEL maintainer="Justin Harringa <justin@harringa.com>"

LABEL com.github.actions.name="GitHub Action for s3_website"
LABEL com.github.actions.description="Provides s3_website to push static sites to AWS (aka JAMstack). Docker wrapper around laurilehmijoki/s3_website"
LABEL com.github.actions.icon="upload-cloud"
LABEL com.github.actions.color="yellow"
COPY LICENSE README.md /

# Install JRE 8 (required for Scala jar)
RUN apt-get update -qq && \
    apt-get install --assume-yes -y --no-install-recommends \
       openjdk-8-jre \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LC_CTYPE en_US.UTF-8
ENV LANG en_US.UTF-8

# Place site files in /site and set the workdir there for s3_website
RUN mkdir /site
WORKDIR /site

# Install s3_website
RUN gem install s3_website && s3_website install

ENTRYPOINT ["s3_website"]
CMD ["help"]
