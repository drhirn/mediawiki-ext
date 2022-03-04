# syntax=docker/dockerfile:1

FROM mediawiki:latest

ARG buildno
ARG gitcommithash
ARG dbname
ARG dbserver
ARG dbuser
ARG dbuserpwd
ARG server
ARG adminpwd
ARG adminuser

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"

RUN apt update
RUN apt install htmldoc -y
RUN apt install wget -y
RUN apt install unzip -y
RUN apt install libzip4 -y
RUN apt install cron -y

COPY ./cron_wiki /etc/cron.d/cron_wiki
RUN chmod 0644 /etc/cron.d/cron_wiki
RUN crontab /etc/cron.d/cron_wiki

RUN git clone --depth 1 https://gitlab.com/organicdesign/PdfBook.git /var/www/html/extensions/PdfBook
RUN git clone --depth 1 https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks.git /var/www/html/extensions/AdminLinks
RUN git clone --depth 1 https://phabricator.wikimedia.org/diffusion/EHET/extension-headertabs.git /var/www/html/extensions/HeaderTabs
#RUN git clone --depth 1 --branch REL1_35 https://github.com/wikimedia/mediawiki-extensions-UploadWizard.git /var/www/html/extensions/UploadWizard

RUN wget https://github.com/composer/getcomposer.org/raw/2dce1a337ceed821c5e243bd54ca11b61e903a2a/web/download/2.1.14/composer.phar

RUN mkdir /external_includes
COPY ./.secrets/dbconn.php /external_includes
RUN chgrp www-data /external_includes/dbconn.php
RUN chmod 640 /external_includes/dbconn.php

COPY ./composer.local.json /var/www/html

RUN php composer.phar update --no-dev

RUN php maintenance/install.php --dbname=$dbname --dbserver=$dbserver --installdbuser=$dbuser --installdbpass=$dbuserpwd --dbuser=$dbuser --dbpass=$dbuserpwd --server=$server --scriptpath=/ --lang=de --pass=$adminpwd "Wiki Name" $adminuser

COPY ./LocalSettings.php /var/www/html
RUN chown www-data:www-data ./LocalSettings.php && chmod 400 ./LocalSettings.php

RUN php maintenance/update.php --skip-external-dependencies --quick

CMD ["cron", "-f"]