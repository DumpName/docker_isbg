# This is a Docker Image for the Tool isbg

![Generic badge](https://img.shields.io/badge/user4711%2Fisbg-v0.7-yellow?style=for-the-badge)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/user4711/isbg/latest?style=for-the-badge)


Docker container that uses [isbg](https://gitlab.com/isbg/isbg) and [imapfilter](https://github.com/lefcha/imapfilter) to filter out spam from a remote IMAP server.
The Docker Image is based on [Debians slim Stable Image](https://hub.docker.com/_/debian).

Configuration: There are 2 volumes, their content is initialized during container startup:

- `/var/lib/spamassassin/` : holds the SpamAssassin data files, to keep them between container resets.
- `/var/lib/mailaccounts` : holds the IMAP accounts configuration.

To configure your IMAP accounts, create a new .conf file in the `/var/lib/mailaccounts` volume for each IMAP account that you want to be filtered. The files are JSON files, see the example below to learn about mandatory and optional parameters.

The container runs a learning process on startup, so do not leave a configuration with a huge email directory active if you want the container to start in a reasonnable time.

**Note: As this image needs to store your _password in cleartext_ you should only use it in an environment that you fully trust!** Be aware of the risk that this involves!

## Dependencies:

[![Generic badge](https://img.shields.io/badge/debian-bullseye--slim-brightgreen.svg?style=for-the-badge)](https://hub.docker.com/_/debian)
[![Generic badge](https://img.shields.io/badge/isbg-2.3.1-brightgreen.svg?style=for-the-badge)](https://gitlab.com/isbg/isbg)
[![Generic badge](https://img.shields.io/badge/imapfilter-1:2.7.5--1-brightgreen.svg?style=for-the-badge)](https://github.com/lefcha/imapfilter)
[![Generic badge](https://img.shields.io/badge/docopt-0.6.2-brightgreen.svg?style=for-the-badge)](https://github.com/docopt/docopt)
[![Generic badge](https://img.shields.io/badge/spamassassin-3.4.6--1-brightgreen.svg?style=for-the-badge)](https://spamassassin.apache.org/)
[![Generic badge](https://img.shields.io/badge/spamc-3.4.6--1-brightgreen.svg?style=for-the-badge)](https://spamassassin.apache.org/)
[![Generic badge](https://img.shields.io/badge/dcc-2.3.168-brightgreen.svg?style=for-the-badge)](https://www.dcc-servers.net/dcc/)
[![Generic badge](https://img.shields.io/badge/pyzor-1.0.0--6-brightgreen.svg?style=for-the-badge)](https://www.pyzor.org/en/latest/index.html)
[![Generic badge](https://img.shields.io/badge/razor-2.85--4.2+b7-brightgreen.svg?style=for-the-badge)](https://de.wikipedia.org/wiki/Vipul%E2%80%99s_Razor)


## Configuration:

Each account config file must follow the following directive (see .example file in accounts folder):

```
{
  "server": "mail.somewhere.com",
  "username": "somebody@somewhere.com",
  "password": "Password",
  "isGmail": "no",                        //Optional; Default = no
  "spamSubject": "[SPAM?]",               //Optional;
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
- `isGmail`: Gmail has a few unique ways that they interact with a mail client. isbg
  must be considered to be a client due to interacting with the Gmail servers
  over IMAP, and thus, should conform to these special requirements for proper
  integration.
- `spamSubject`: Messages with this prefix will automaticaly sorted to spam without scoring them, usefull if your mailbox provider is offering this feature
- `report`: Flag whether or not the `--noreport` for isbg should be set or not. yes = Flag is not set, no (Default) = Flag is set
- `spamLifetime`: Duration in days after which the spam-messages in your spambox should be automatically deleted
- `ham`: Ham folder where you can move wrong spam detections. Spamassassin will learn these in the next learning run as ham. Messages placed here will automaticaly be moved in your inbox after they have been learned
- `sent`: Your mailbox for sent messages. Spamassassin will use this folder to learn ham messages.

## Variables:

The following Docker Environment Variables can be set:


| Variable          | Default                | Description                                                                                                         |
|-------------------|------------------------|---------------------------------------------------------------------------------------------------------------------|
| CRON_HOUR         | 1                      | hour for daily spam learning                                                                                        |
| CRON_MINUTE       | 30                     | minute for daily spam learning                                                                                      |
| TZ                | UTC                    | time zone                                                                                                           |
| USERNAME          | debian-spamd           | username to run spammassin-deamon                                                                                   |
 | HAM_BATCH_SIZE    | 50                     | max amount of ham messages to learn per learning run                                                                |
 | SPAM_BATCH_SIZE   | 50                     | max amount of spam messages to learn per learning run                                                               |
 | FILTER_BATCH_SIZE | 50                     | max amount of messages to filter per run                                                                            |
 | MAX_MAIL_SIZE     | 120000                 | mails bigger than this size will be skipped by SA. (BYTES)                                                          |
| EXTRA_OPTIONS     | --nouser-config        | additional options for spamasssassin                                                                                |
| PYZOR_SITE        | public.pyzor.org:24441 | pyzor URI                                                                                                           |
| DETAILED_LOGGING  | false                  | enables verbose logging of isbg/SA                                                                                  |
| LIST_FOLDERS      | false                  | Print list of mailboxes and folders on startup. Settings this to "only" will terminate the container after listing. |

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](http://perso.crans.org/besson/LICENSE.html)
