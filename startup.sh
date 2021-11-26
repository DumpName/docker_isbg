#!/bin/bash

cd /root
if [ ! -f startup_done ]; then
  pyzor --homedir /etc/mail/spamassassin/ discover
  razor-admin -home=/etc/mail/spamassassin/.razor -register
  razor-admin -home=/etc/mail/spamassassin/.razor -create
  razor-admin -home=/etc/mail/spamassassin/.razor -discover
  touch startup_done
fi

function learnSpam {
  echo "updating SpamAssassin rules"
  sa-update -v --refreshmirrors
  /usr/bin/imapfilter -c /home/spamassassin/imapfilter/spamTrainer.lua
  spamLearned=$(date +%Y%m%d)
}

function findSpam {
  /usr/bin/imapfilter -c /home/spamassassin/imapfilter/spamFilter.lua
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


echo "running sa-learn"
sa-learn --force-expire

echo "starting spamassassin"
service spamassassin start

learnSpam

main


