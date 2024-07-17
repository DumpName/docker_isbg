#!/bin/bash

if [ ! -f /root/currentState/startupDone ]; then
  exit 0;
fi

if [[ $DETAILED_LOGGING == "true" ]]; then
    >&2 echo "HELTHCHECK: DETAILED_LOGGING"
fi

service spamd status > /dev/null

if [[ $? -eq 1 ]]; then
  if [[ $DETAILED_LOGGING == "true" ]]; then
    >&2 echo "HELTHCHECK: spamd stopped"
  fi
  exit 1
fi

if [ -f /root/currentState/learningSpam ] || [ -f /root/currentState/searchingSpam ]; then
  if [ ! -f /var/lib/spamassassin/.cache/isbg/lock ]; then
    if [[ $DETAILED_LOGGING == "true" ]]; then
      >&2 echo "HELTHCHECK: No ISBG lockfile found"
    fi
    exit 1
  fi
  exit 0
fi

nextScheduledLearn=$(($(date -r /root/currentState/spamLearned +%s) + (24+2)*60*60 ))
if [[ $(date +%s) -gt $nextScheduledLearn ]]; then
  if [[ $DETAILED_LOGGING == "true" ]]; then
    >&2 echo "HELTHCHECK: No Spam training in last 26 Hours"
  fi
  exit 1
fi

nextScheduledSearch=$(($(date -r /root/currentState/spamSearched +%s) + 60*3 ))
if [[ $(date +%s) -gt nextScheduledSearch ]]; then
  if [[ $DETAILED_LOGGING == "true" ]]; then
    >&2 echo "HELTHCHECK: No spam search in last 3 minutes"
  fi
  exit 1
fi

exit 0;