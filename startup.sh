#!/bin/bash

if [ ! -f startup_done ]; then
  mv /root/imapfilter/dkjson.lua /usr/share/lua/5.2/
  mv /root/imapfilter/confLoader.lua /usr/share/lua/5.2/
  mv /root/imapfilter/imapfilterSettings.lua /usr/share/lua/5.2/
  pyzor --homedir /etc/mail/spamassassin/ discover
  echo "$CRON_MINUTE $CRON_HOUR * * *   root sa-update kill -HUP \`cat /var/run/spamd.pid\`" > /etc/cron.d/sa-update
  #mkdir -p /var/run/dcc
  #/var/dcc/libexec/dccifd -tREP,20 -tCMN,5, -llog -wwhiteclnt -Uuserdirs -SHELO -Smail_host -SSender -SList-ID
  if [ ! -d /var/lib/spamassassin/accounts ]; then
    mkdir /var/lib/spamassassin/accounts
  fi
  chown -R $USERNAME /var/lib/spamassassin
  su $USERNAME bash -c"
    cd ~$USERNAME
    mkdir -p .razor .spamassassin .pyzor
    razor-admin -discover
    razor-admin -create -conf=razor-agent.conf
    razor-admin -register -l
    echo $PYZOR_SITE > .pyzor/servers
    chmod g-rx,o-rx .pyzor .pyzor/servers"
  echo 'OPTIONS="--allow-tell --create-prefs --max-children 5 --helper-home-dir=/var/lib/spamassassin --username=USERNAMETOUSE EXTRA_OPTIONS"' >> /etc/default/spamassassin
  sed -i "s/USERNAMETOUSE/$USERNAME/" /etc/default/spamassassin
  sed -i "s/EXTRA_OPTIONS/$EXTRA_OPTIONS/" /etc/default/spamassassin
  touch startup_done
fi

function learnSpam {
  echo "updating SpamAssassin rules"
  sa-update -v --refreshmirrors
  /usr/bin/imapfilter -c /root/imapfilter/spamTrainer.lua
  spamLearned=$(date +%Y%m%d)
}

function findSpam {
  /usr/bin/imapfilter -c /root/imapfilter/spamFilter.lua
}

function main {
  echo "starting Main Loop"
  while true; do
    currentDay=$(date +%Y%m%d)
    currentTime=$(date +%H:%M)
    if [[ $currentDay -ne $spamLearned ]] && [[ "$currentTime" > "03:00" ]] && [[ "$currentTime" < "04:00" ]]; then
      learnSpam
    fi
    findSpam
    sleep $(( 60 - 10#$(date +%S) ))
  done
}

rm -f /var/lib/spamassassin/.cache/isbg/lock

echo "running sa-learn"
sa-learn --force-expire

echo "starting spamassassin"
service spamassassin start

learnSpam

main


