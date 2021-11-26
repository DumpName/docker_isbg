FROM debian:bullseye-slim

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license="GNU GPL-3.0" \
    org.label-schema.name=spamassassin \
    org.label-schema.vcs-ref=$VCS_REF

#Set Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    CRON_HOUR=1 CRON_MINUTE=30 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441

#Set Versions of used Software
ARG DCC_VERSION=2.3.168
ARG SPAMC_VERSION=3.4.6-1
ARG SPAMD_VERSION=3.4.6-1
ARG IMAPFILTER_VERSION=1:2.7.5-1
ARG ISBG_VERSION=2.3.1
ARG DOCPOT_VERSION=0.6.2
ARG DCC_SHA=3fc932325b36a46a93258bdaa483d00ee3a826bea1d00de04f6e84cfbea63bc2
ARG ISBG_SHA=c51ac52864f8275d9db6bf106b0b9aa850216dc4b059e58e069f07206aeac78b
ARG SPAMD_UID=783

#Install Dependencies
RUN apt-get -y update && \
    apt-get -y --no-install-recommends install \
     ca-certificates cron curl gcc libc6-dev libdbd-mysql-perl \
     libmail-dkim-perl libnet-ident-perl make pyzor razor gpg gpg-agent python3 python3-pip \
     redis-server \
     imapfilter=$IMAPFILTER_VERSION \
     spamassassin=$SPAMD_VERSION \ 
     spamc=$SPAMC_VERSION \
RUN  usermod --uid $SPAMD_UID $USERNAME --shell /bin/bash && \
     mv /etc/mail/spamassassin/local.cf /etc/mail/spamassassin/local.cf-dist && \
# Spamassassin daemon config
    rm -f /etc/default/spamassassin && echo "ENABLED=1" >> /etc/default/spamassassin
# Install ISBG
RUN python3 -m pip install isbg==$ISBG_VERSION && \
    mkdir /root/imapfilter/ \
# Configure Razor  \
RUN sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf
#    sed -i 's/DCCIFD_ENABLE=off/DCCIFD_ENABLE=on/' /var/dcc/dcc_conf && \
#    sed -i '/^#\s*loadplugin .\+::DCC/s/^#\s*//g' /etc/spamassassin/v310.pre && \
# cleanup \
RUN python3 -m pip cache purge && \
    apt-get purge -y binutils libc6-dev libgcc-8-dev python-pip-whl python3-setuptools python3-pkg-resources python3-wheel \
     linux-libc-dev make && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* && \
    rm -rf /root/.cache/*
# add imapfilter files
COPY imapfilterExec/* /root/imapfilter/   

COPY startup.sh /root/
VOLUME ["/var/lib/spamassassin"]
#EXPOSE 783
ENTRYPOINT ["/root/startup.sh"]
