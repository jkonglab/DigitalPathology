FROM ruby:2.5.1

ENV BUNDLER_VERSION=1.17.3

RUN apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
    postgresql-client \
    nodejs \
    git \
    gtk-doc-tools \
    libxml2-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libexif-dev \
    libgsf-1-dev \
    liblcms2-dev \
    imagemagick \
    curl \
    libwebp-dev \
    libvips \
    libvips-dev \
    libvips-tools \
    python \
    openslide-tools \
    python3-openslide \
    yarn

WORKDIR /app

COPY Gemfile* ./

COPY . .

RUN gem install bundler -v 1.17.3

RUN bundle install

ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]
