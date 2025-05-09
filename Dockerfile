ARG ARCH=
FROM ${ARCH}debian:bookworm-slim
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license="GNU GPL-3.0" \
    org.label-schema.name=spamassassin \
    org.label-schema.vcs-ref=$VCS_REF
SHELL ["/bin/bash", "-c"]

#Set Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    CRON_HOUR=1 CRON_MINUTE=30 \
    HAM_BATCH_SIZE=50 SPAM_BATCH_SIZE=50 FILTER_BATCH_SIZE=50 \
    MAX_MAIL_SIZE=120000 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441 \
    DETAILED_LOGGING="false" \
    LIST_FOLDERS="false" \
    INTERVAL_MINUTES=1

#Set Versions of used Software
ARG SPAMC_VERSION=4.0.1-1~deb12u1
ARG SPAMD_VERSION=4.0.1-1~deb12u1
ARG DCC_VERSION=2.3.169
ARG PYZOR_VERSION=1:1.0.0-6
ARG RAZOR_VERSION=1:2.85-9
ARG IMAPFILTER_VERSION=1:2.8.1-1
ARG ISBG_VERSION=2.3.1
ARG DOCPOT_VERSION=0.6.2
ARG ISBG_SHA=c51ac52864f8275d9db6bf106b0b9aa850216dc4b059e58e069f07206aeac78b
ARG SPAMD_UID=783
ARG PYTHON_VERSION=3.11.2-1+b1

#Install Dependencies
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
        wget ca-certificates cron curl gcc libc6-dev libdbd-mysql-perl \
        libmail-dkim-perl libnet-ident-perl make gpg gpg-agent \
        python3=$PYTHON_VERSION \
        python3-pip python3-venv \
        pyzor=$PYZOR_VERSION \
        razor=$RAZOR_VERSION \
        imapfilter=$IMAPFILTER_VERSION \
        spamd=$SPAMD_VERSION \
        spamc=$SPAMC_VERSION && \
    wget -O /root/dcc.tar.Z "https://www.dcc-servers.net/src/dcc/old/dcc-$DCC_VERSION.tar.Z" && \
    tar xfvz /root/dcc.tar.Z -C /root/ && \
    cd -- "/root/dcc-$DCC_VERSION" && \
    CFLAGS="-O2 -fstack-protector" DCC_CFLAGS="-O2 -fstack-protector" ./configure --homedir=/var/lib/spamassassin/.dcc && make && make install && \
    cd /root/
# Install Spamassassin
RUN usermod --uid $SPAMD_UID $USERNAME && \
    usermod --shell /bin/bash $USERNAME && \
    usermod --home /var/lib/spamassassin $USERNAME && \
    rm /etc/mail/spamassassin/local.cf && \
# Spamassassin daemon config
    rm -f /etc/default/spamd && echo "ENABLED=1" >> /etc/default/spamd
# Install ISBG
RUN mkdir /usr/local/pythonVenv && \
    python3 -m venv /usr/local/pythonVenv && \
    source /usr/local/pythonVenv/bin/activate && \
    python3 -m pip install isbg==$ISBG_VERSION && \
    mkdir /root/imapfilter/
# Configure Razor  \
RUN sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf
# cleanup \
RUN python3 -m pip cache purge && \
    apt-get purge -y binutils libc6-dev libgcc-8-dev python-pip-whl python3-setuptools python3-pkg-resources python3-wheel \
     linux-libc-dev make wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* && \
    rm -rf /root/.cache/* && \
    rm -rf "/root/dcc-$DCC_VERSION" && \
    rm -f /root/dcc.tar.Z
RUN echo "CAHCEBUST"
# add imapfilter files
COPY imapfilterExec/* /root/imapfilter/
COPY spamassassinConf/* /etc/mail/spamassassin/
COPY scripts/* /root/
RUN rm /usr/local/pythonVenv/lib/python3.11/site-packages/isbg/imaputils.py
RUN chmod +x /root/*.sh
COPY isbg/* /usr/local/pythonVenv/lib/python3.11/site-packages/isbg/

VOLUME ["/var/lib/spamassassin"]
VOLUME ["/var/lib/mailaccounts"]
ENTRYPOINT ["/root/startup.sh"]
HEALTHCHECK --interval=1m --timeout=10s --start-period=5m \
    CMD /root/status.sh