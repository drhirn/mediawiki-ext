FROM mediawiki:lts

ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"

RUN apt update
RUN apt install htmldoc -y
RUN apt install wget -y
RUN apt install unzip -y
RUN apt install libzip4 -y

RUN git clone --depth 1 https://gitlab.com/organicdesign/PdfBook.git /var/www/html/extensions/PdfBook
RUN git clone --depth 1 https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks.git /var/www/html/extensions/AdminLinks
RUN git clone --depth 1 https://phabricator.wikimedia.org/diffusion/EHET/extension-headertabs.git /var/www/html/extensions/HeaderTabs
RUN git clone --branch REL1_35 https://github.com/wikimedia/mediawiki-extensions-UploadWizard.git /var/www/html/extensions/UploadWizard

RUN wget https://github.com/composer/getcomposer.org/raw/2dce1a337ceed821c5e243bd54ca11b61e903a2a/web/download/2.1.14/composer.phar

RUN mkdir /external_includes
COPY ./.secrets/dbconn.php /external_includes
RUN chgrp www-data /external_includes/dbconn.php
RUN chmod 640 /external_includes/dbconn.php

COPY ./composer.local.json /var/www/html
COPY ./LocalSettings.php /var/www/html
RUN chown www-data:www-data ./LocalSettings.php && chmod 400 ./LocalSettings.php

RUN php composer.phar update --no-dev

RUN php maintenance/update.php --skip-external-dependencies --quick