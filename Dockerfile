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

COPY ./composer.local.json /var/www/html
COPY ./LocalSettings.php /var/www/html

#RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
#RUN php composer-setup.php
#RUN php -r "unlink('composer-setup.php');"

RUN php composer.phar update --no-dev

RUN php maintenance/update.php --skip-external-dependencies --quick