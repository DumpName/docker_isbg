if [ ! -f /root/currentState/startupDone ]; then
  exit 0;
fi

service spamassassin status > /dev/null || exit 1;

if [ ! -f /root/currentState/learningSpam ] || [ ! -f /root/currentState/spamSearched ]; then
  if [ ! -f /var/lib/spamassassin/.cache/isbg/lock ]; then
    exit 1;   #No Lockfile found -> isbg is not running system might have a hangup
  fi;
  exit 0;
fi;

nextScheduledLearn = $(($(date -r /root/currentState/spamLearned +s) + (24+2)*60*60 ))
if [[ $(date -r /root/currentState/spamLearned +s) -gt $nextScheduledLearn ]]; then
  exit 1; #No spam learn in last 26 hours
fi

nextScheduledSearch = $(($(date -r /root/currentState/spamSearched +s) + 60*3 ))
if [[ $(date -r /root/currentState/spamLearned +s) -gt $nextScheduledLearn ]]; then
  exit 1; #No spam search in last 3 minutes
fi

exit 0;