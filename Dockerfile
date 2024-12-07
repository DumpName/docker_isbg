ARG ARCH=
FROM ${ARCH}debian:bullseye-slim
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
    HAM_BATCH_SIZE=50 SPAM_BATCH_SIZE=50 FILTER_BATCH_SIZE=50 \
    MAX_MAIL_SIZE=120000 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441 \
    DETAILED_LOGGING="false"

#Set Versions of used Software
ARG SPAMC_VERSION=3.4.6-1
ARG SPAMD_VERSION=3.4.6-1
ARG IMAPFILTER_VERSION=1:2.7.5-1
ARG ISBG_VERSION=2.3.1
ARG DOCPOT_VERSION=0.6.2
ARG ISBG_SHA=c51ac52864f8275d9db6bf106b0b9aa850216dc4b059e58e069f07206aeac78b
ARG SPAMD_UID=783

#Install Dependencies
RUN apt-get -y update && \
    apt-get -y --no-install-recommends install \
        ca-certificates cron curl gcc libc6-dev libdbd-mysql-perl \
        libmail-dkim-perl libnet-ident-perl make pyzor razor gpg gpg-agent python3 python3-pip \
        imapfilter=$IMAPFILTER_VERSION \
        spamassassin=$SPAMD_VERSION \
        spamc=$SPAMC_VERSION
RUN usermod --uid $SPAMD_UID $USERNAME && \
    usermod --shell /bin/bash $USERNAME && \
    usermod --home /var/lib/spamassassin $USERNAME && \
    rm /etc/mail/spamassassin/local.cf && \
# Spamassassin daemon config
    rm -f /etc/default/spamassassin && echo "ENABLED=1" >> /etc/default/spamassassin
# Install ISBG
RUN python3 -m pip install isbg==$ISBG_VERSION && \
    mkdir /root/imapfilter/
# Configure Razor  \
RUN sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf
# cleanup \
RUN python3 -m pip cache purge && \
    apt-get purge -y binutils libc6-dev libgcc-8-dev python-pip-whl python3-setuptools python3-pkg-resources python3-wheel \
     linux-libc-dev make && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* && \
    rm -rf /root/.cache/*
# add imapfilter files
COPY imapfilterExec/* /root/imapfilter/
COPY spamassassinConf/* /usr/share/spamassassin/
COPY scripts/* /root/
RUN chmod +x /root/*.sh

VOLUME ["/var/lib/spamassassin"]
VOLUME ["/var/lib/mailaccounts"]
ENTRYPOINT ["/root/startup.sh"]
HEALTHCHECK --interval=1m --timeout=10s --start-period=1m \
    CMD /root/status.sh