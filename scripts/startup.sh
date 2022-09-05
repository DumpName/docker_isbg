#!/bin/bash

mkdir /root/currentState
if [ ! -f /root/currentState/startupDone ]; then
  mkdir -p /usr/share/lua/5.2/
  mv /root/imapfilter/dkjson.lua /usr/share/lua/5.2/
  mv /root/imapfilter/confLoader.lua /usr/share/lua/5.2/
  mv /root/imapfilter/imapfilterSettings.lua /usr/share/lua/5.2/
  pyzor --homedir /var/lib/spamassassin/ discover
  echo "$CRON_MINUTE $CRON_HOUR * * *   root sa-update kill -HUP \`cat /var/run/spamd.pid\`" > /etc/cron.d/sa-update
  #mkdir -p /var/run/dcc
  #/var/dcc/libexec/dccifd -tREP,20 -tCMN,5, -llog -wwhiteclnt -Uuserdirs -SHELO -Smail_host -SSender -SList-ID
  if [ ! -d /var/lib/mailaccounts ]; then
    mkdir /var/lib/mailaccounts
  fi
  chown -R $USERNAME /var/lib/spamassassin
  su $USERNAME bash -c"
      cd ~$USERNAME
      mkdir -p .razor .spamassassin .pyzor .dcc"
  if [ ! -f /var/lib/spamassassin/.razor/identity ]; then
    su $USERNAME razor-admin -register -l
  fi
  su $USERNAME bash -c"
    cd ~$USERNAME
    razor-admin -discover
    razor-admin -create -conf=razor-agent.conf
    echo $PYZOR_SITE > .pyzor/servers
    chmod g-rx,o-rx .pyzor .pyzor/servers"
  echo 'OPTIONS="--allow-tell --create-prefs --max-children 5 --helper-home-dir=/var/lib/spamassassin --username=USERNAMETOUSE EXTRA_OPTIONS"' >> /etc/default/spamassassin
  sed -i "s/USERNAMETOUSE/$USERNAME/" /etc/default/spamassassin
  sed -i "s/EXTRA_OPTIONS/$EXTRA_OPTIONS/" /etc/default/spamassassin
  #Clear old lock files
  rm /var/lib/spamassassin/.cache/isbg/lock 2> /dev/null
  rm /var/lib/spamassassin/.spamassassin/bayes.lock* 2> /dev/null
  #Create user config file if not existing
  touch /var/lib/spamassassin/.spamassassin/user_prefs
  touch /root/currentState/startupDone
fi

function learnSpam {
  touch /root/currentState/learningSpam
  echo "updating SpamAssassin rules"
  sa-update -v --refreshmirrors
  /usr/bin/imapfilter -c /root/imapfilter/spamTrainer.lua
  rm /root/currentState/learningSpam
  touch /root/currentState/spamLearned
}

function findSpam {
  touch /root/currentState/searchingSpam
  /usr/bin/imapfilter -c /root/imapfilter/spamFilter.lua
  rm /root/currentState/searchingSpam
  touch /root/currentState/spamSearched
}

function main {
  echo "starting Main Loop"
  while true; do
    currentDay=$(date +%Y%m%d)
    currentTime=$(date +%H:%M)
    if [[ $currentDay -ne $(date -r /root/currentState/spamLearned +%Y%m%d) ]] && [[ "$currentTime" > "03:00" ]] && [[ "$currentTime" < "04:00" ]]; then
      learnSpam
    fi
    findSpam
    sleep $(( 60 - 10#$(date +%S) ))
  done
}

echo "running sa-learn"
sa-learn --force-expire

echo "starting spamassassin"
service spamassassin start

learnSpam

main


