FROM debian:stable-slim

# timezone name that can be overridden when building the container
#ARG CTNR_TZ=UTC

### Disable Features From Base Image
#ENV ENABLE_SMTP=false

### Create User

RUN set -x && \
    mkdir /home/spamassassin && \
    addgroup --gid 783 spamassassin && \
    adduser --system --disabled-password --gid 783 --uid 783 --home /home/spamassassin --shell /bin/bash spamassassin
### Install Dependencies
RUN apt-get update && \
    apt-get upgrade && \
    apt-get install -y \
           sa-compile \
           razor \
           pyzor \
           spamassassin \
           imapfilter \
           python3 \
           python3-pip \
    && \
    /usr/bin/env python3 -m pip install docopt==0.6.2 && \
    /usr/bin/env python3 -m pip install isbg

### Cleanup
RUN apt-get clean && \
    rm -rf /var/mail/spamassassin && \
    rm -rf /var/lib/spamassassin && \
    rm -rf /var/cache/apk/* && \
    pip3 cache purge && \
    rm -rf /root/.cache/*

## Initial Config
RUN rm -f /etc/default/spamassassin && \
   # mkdir /etc/default && \
    echo "ENABLED=1" >> /etc/default/spamassassin && \
    echo 'OPTIONS="--allow-tell --create-prefs --max-children 5 --helper-home-dir -s stderr 2>/dev/null"' >> /etc/default/spamassassin && \
    echo "use_pyzor 1" >> /etc/mail/spamassassin/local.cf && \
    echo "pyzor_options --homedir /home/spamassassin/.spamassassin" >> /etc/mail/spamassassin/local.cf && \
    echo "use_razor2 1" >> /etc/mail/spamassassin/local.cf && \
    echo "razor_config /home/spamassassin/.spamassassin/.razor/razor-agent.conf" >> /etc/mail/spamassassin/local.cf


## Add running Files

WORKDIR /root

RUN mkdir /root/accounts ; \
    mkdir /home/spamassassin/.spamassassin ; \
    mkdir /home/spamassassin/imapfilter ;

ADD imapfilterExec/spamFilter.lua /home/spamassassin/imapfilter/
ADD imapfilterExec/spamTrainer.lua /home/spamassassin/imapfilter/
ADD imapfilterExec/imapfilterSettings.lua /usr/share/lua/5.2/
ADD imapfilterExec/dkjson.lua /usr/share/lua/5.2/
ADD imapfilterExec/confLoader.lua /usr/share/lua/5.2/
ADD startup.sh /root/

RUN chown -R spamassassin:spamassassin /home/spamassassin/ && \
    chmod -R 777 /home/spamassassin/ && \
#    chmod -R 544 /home/spamassassin/accounts/ && \
    chmod u+x startup.sh

VOLUME /home/spamassassin/accounts
VOLUME /home/spamassassin/.spamassassin

ENTRYPOINT /bin/bash /root/startup.sh

# timezone to set
#ENV CTNR_TZ=${CTNR_TZ}

# install dependencies
#RUN apk update && \
#    apk add  \
#      cron \
#      imapfilter \
#      python3 \
#      py3-pip \
#      py3-setuptools \
#      p3-pyzor \
#      razor \
#      spamassassin \
#    && \
#    /usr/bin/env python3 -m pip3 install docopt==0.6.2 && \
#    /usr/bin/env python3 -m pip3 install isbg

#WORKDIR /root

# prepare directories and files

#RUN mkdir /root/accounts ; \
#    mkdir /root/imapfilter-exec ; \
#    mkdir /root/spamassassin ; \
	

#RUN mkdir /root/accounts ; \
#    mkdir /root/.imapfilter ; \
#    mkdir -p /var/spamassassin/bayesdb ; \
#    chown -R debian-spamd:mail /var/spamassassin ; \
#    chmod u+x startup ; \
#    chmod u+x *.sh ; \
#    crontab cron_scans && rm cron_scans ; \
#    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin ; \
#    sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin ; \
#    sed -i 's/^OPTIONS=".*"/OPTIONS="--allow-tell --max-children 5 --helper-home-dir -u debian-spamd -x --virtual-config-dir=\/var\/spamassassin -s mail"/' /etc/default/spamassassin ; \
#    echo "bayes_path /var/spamassassin/bayesdb/bayes" >> /etc/spamassassin/local.cf ; \
#    echo "allow_user_rules 1" >> /etc/spamassassin/local.cf ; \
#    mv 9*.cf /etc/spamassassin/ ; \
#    echo "alias logger='/usr/bin/logger -e'" >> /etc/bash.bashrc ; \
#    echo "LANG=en_US.UTF-8" > /etc/default/locale ; \
#    if [ -e "/usr/share/zoneinfo/${CTNR_TZ}" ]; then \
#      unlink /etc/localtime ; \
##      ln -s "/usr/share/zoneinfo/${CTNR_TZ}" /etc/localtime ; \
#      unlink /etc/timezone ; \
#      ln -s "/usr/share/zoneinfo/${CTNR_TZ}" /etc/timezone ; \
#      dpkg-reconfigure -f noninteractive tzdata ; \
#    fi

# volumes
#VOLUME /var/spamassassin
#VOLUME /root/.imapfilter
#VOLUME /root/accounts

#CMD /root/startup && tail -n 0 -F /var/log/*.log
