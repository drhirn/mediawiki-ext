# syntax=docker/dockerfile:1

# docker build --no-cache -t drhirn/mediawiki --secret id=dbname,src=./.secrets/wiki_setup_test --build-arg env=test .

FROM mediawiki:latest

ARG env

RUN apt update && apt install --no-install-recommends --quiet --yes \
  cron \
  htmldoc \
  libzip4 \
  unzip \
  wget

COPY ./cron_wiki /etc/cron.d/cron_wiki
RUN chmod 0644 /etc/cron.d/cron_wiki && crontab /etc/cron.d/cron_wiki

RUN git clone --depth 1 https://gitlab.com/organicdesign/PdfBook.git /var/www/html/extensions/PdfBook && \
  git clone --depth 1 https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks.git /var/www/html/extensions/AdminLinks && \
  git clone --depth 1 https://phabricator.wikimedia.org/diffusion/EHET/extension-headertabs.git /var/www/html/extensions/HeaderTabs

RUN wget https://github.com/composer/getcomposer.org/raw/2dce1a337ceed821c5e243bd54ca11b61e903a2a/web/download/2.1.14/composer.phar

RUN mkdir /external_includes
COPY ./.secrets/dbconn.php /external_includes
RUN chgrp www-data /external_includes/dbconn.php && \
  chmod 640 /external_includes/dbconn.php

COPY ./composer.local.json /var/www/html

RUN php composer.phar update --no-dev --no-progress

RUN --mount=type=secret,id=wiki_setup_$env /usr/local/bin/php maintenance/install.php --quiet $(cat /run/secrets/wiki_setup_$env)

COPY ./LocalSettings.php /var/www/html
RUN chown www-data:www-data ./LocalSettings.php && chmod 400 ./LocalSettings.php

RUN php maintenance/update.php --skip-external-dependencies --quick