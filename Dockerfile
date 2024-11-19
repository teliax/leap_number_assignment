# Base image
FROM ruby:3.2-slim-bullseye
ENV LANG C.UTF-8

RUN apt-get -y update

## Install Dependcies
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    less \
    git \
    telnet \
    vim \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Install mysql lib dependency
RUN apt-get update -qq && apt-get install -y default-libmysqlclient-dev default-mysql-client

# make sure the package repository is up to date
RUN apt-get -y update

# Set app installation directory
ENV APP_ROOT="/app"
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock ./

## Install bundler
RUN gem install bundler -v 2.4.12

## Install dependencies
RUN bundle config set deployment 'true'

RUN bundle install

COPY . $APP_ROOT

RUN mkdir -p $APP_ROOT/tmp

CMD ["./bin/runner"]
