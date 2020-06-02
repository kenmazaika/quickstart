FROM ruby:2.7-alpine

RUN apk add --update --no-cache \
      bash \
      binutils-gold \
      build-base \
      curl \
      file \
      g++ \
      gcc \
      git \
      less \
      libc6-compat \
      libstdc++ \
      libffi-dev \
      libc-dev \ 
      linux-headers \
      libxml2-dev \
      libxslt-dev \
      libgcrypt-dev \
      make \
      netcat-openbsd \
      nodejs \
      openssl \
      pkgconfig \
      postgresql-client \
      postgresql-dev \
      python \
      tzdata \
      yarn 

WORKDIR /app

# Setup Environment
ENV GEM_HOME=/usr/local/bundle
ENV PATH=$GEM_HOME/bin:$PATH
ENV YARN_CACHE_FOLDER /yarn
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

RUN mkdir -p $YARN_CACHE_FOLDER
RUN yarn config set cache-folder $YARN_CACHE_FOLDER

# Bundle Install
COPY Gemfile* ./
RUN bundle config build.nokogiri --use-system-libraries

# For production builds set this.
# RUN bundle config set without 'development test'

# Remove deprecation warnings
ENV RUBYOPT "-W:no-deprecated"

RUN bundle check || bundle install

# Yarn Install
COPY package.json yarn.lock ./
RUN yarn install --check-files

# Copy application
ADD . ./

RUN RAILS_ENV=production bundle exec rake assets:precompile

EXPOSE 8081

CMD ["sh", "lib/docker/server.sh"]