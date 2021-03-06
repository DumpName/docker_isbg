# This is a Docker Image for the Tool isbg

Docker container that uses [isbg](https://gitlab.com/isbg/isbg) and [imapfilter](https://github.com/lefcha/imapfilter) to filter out spam from a remote IMAP server.
The Docker Image is based on [Debians slim Stable Image](https://hub.docker.com/_/debian).

Configuration: There are 2 volumes, their content is initialized during container startup:

- `/var/lib/spamassassin/` : holds the SpamAssassin data files, to keep them between container resets.
- `/var/lib/mailaccounts` : holds the IMAP accounts configuration.

To configure your IMAP accounts, create a new .conf file in the `/var/lib/mailaccounts` volume for each IMAP account that you want to be filtered. The files are JSON files, see the example below to learn about mandatory and optional parameters.

The container runs a learning process on startup, so do not leave a configuration with a huge email directory active if you want the container to start in a reasonnable time.

**Note: As this image needs to store your _password in cleartext_ you should only use it in an environment that you fully trust!** Be aware of the risk that this involves!

## Dependencies:

[![Generic badge](https://img.shields.io/badge/debian-bullseye--slim-brightgreen.svg)](https://hub.docker.com/_/debian)
[![Generic badge](https://img.shields.io/badge/isbg-2.3.1-brightgreen.svg)](https://gitlab.com/isbg/isbg)
[![Generic badge](https://img.shields.io/badge/imapfilter-1:2.7.5--1-brightgreen.svg)](https://github.com/lefcha/imapfilter)
[![Generic badge](https://img.shields.io/badge/docopt-0.6.2-brightgreen.svg)](https://github.com/docopt/docopt)
[![Generic badge](https://img.shields.io/badge/spamassassin-3.4.6--1-brightgreen.svg)](https://spamassassin.apache.org/)
[![Generic badge](https://img.shields.io/badge/spamc-3.4.6--1-brightgreen.svg)](https://spamassassin.apache.org/)

## Configuration:

Each account config file must follow the following directive (see .example file in accounts folder):

```
{
  "server": "mail.somewhere.com",
  "username": "somebody@somewhere.com",
  "password": "Password",
  "spamSubject": "[SPAM?]",               //Optional;
  "mailsToScan": 50,                      //Optional; 
  "report": "yes",                        //Optional; Default = no
  "spamLifetime": 30,                     //Optional;
  "folders": {
    "spam": "Spam",
    "ham": "ham",                         //Optional;
    "sent": "Sent",                       //Optional;
    "inbox": "INBOX"
  }
}
```
- `spamSubject`: Messages with this prefix will automaticaly sorted to spam without scoring them, usefull if your mailbox provider is offering this feature
- `mailsToScan`: Limit the amount of messages that will be scaned at a time, applies to filtering and learning!
- `report`: Flag whether or not the `--noreport` for isbg should be set or not. yes = Flag is not set, no (Default) = Flag is set
- `spamLifetime`: Duration in days after which the spam-messages in your spambox should be automatically deleted
- `ham`: Ham folder where you can move wrong spam detections. Spamassassin will learn these in the next learning run as ham. Messages placed here will automaticaly be moved in your inbox after they have been learned
- `sent`: Your mailbox for sent messages. Spamassassin will use this folder to learn ham messages.

## Variables:

The following Docker Environment Variables can be set:



| Variable      | Default                | Description                          |
| --------------- | ------------------------ | -------------------------------------- |
| CRON_HOUR     | 1                      | hour for daily spam learning         |
| CRON_MINUTE   | 30                     | minute for daily spam learning       |
| TZ            | UTC                    | time zone                            |
| USERNAME      | debian-spamd           | username to run spammassin-deamon    |
| EXTRA_OPTIONS | --nouser-config        | additional options for spamasssassin |
| PYZOR_SITE    | public.pyzor.org:24441 | pyzor URI                            |

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)
