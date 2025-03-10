# This is a Docker Image for the Tool isbg

![Generic badge](https://img.shields.io/badge/user4711%2Fisbg-v1.0-brightgreen?style=for-the-badge)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/user4711/isbg/latest?style=for-the-badge)


Docker container that uses [isbg](https://gitlab.com/isbg/isbg) and [imapfilter](https://github.com/lefcha/imapfilter) to filter out spam from a remote IMAP server.
The Docker Image is based on [Debians slim Stable Image](https://hub.docker.com/_/debian).

Configuration: There are 2 volumes, their content is initialized during container startup:

- `/var/lib/spamassassin/` : holds the SpamAssassin data files, to keep them between container resets.
- `/var/lib/mailaccounts` : holds the IMAP accounts configuration.

To configure your IMAP accounts, create a new .conf file in the `/var/lib/mailaccounts` volume for each IMAP account that you want to be filtered. The files are JSON files, see the example below to learn about mandatory and optional parameters.

The container runs a learning process on startup, so do not leave a configuration with a huge email directory active if you want the container to start in a reasonable time.

**Note: As this image needs to store your _password in cleartext_ you should only use it in an environment that you fully trust!** Be aware of the risk that this involves!

## Dependencies:

[![Generic badge](https://img.shields.io/badge/debian-bullseye--slim-brightgreen.svg?style=for-the-badge)](https://hub.docker.com/_/debian)
[![Generic badge](https://img.shields.io/badge/isbg-2.3.1-brightgreen.svg?style=for-the-badge)](https://gitlab.com/isbg/isbg)
[![Generic badge](https://img.shields.io/badge/imapfilter-1:2.8.1--1-brightgreen.svg?style=for-the-badge)](https://github.com/lefcha/imapfilter)
[![Generic badge](https://img.shields.io/badge/docopt-0.6.2-brightgreen.svg?style=for-the-badge)](https://github.com/docopt/docopt)
[![Generic badge](https://img.shields.io/badge/spamd-4.0.0--6-brightgreen.svg?style=for-the-badge)](https://spamassassin.apache.org/)
[![Generic badge](https://img.shields.io/badge/spamc-4.0.0--6-brightgreen.svg?style=for-the-badge)](https://spamassassin.apache.org/)
[![Generic badge](https://img.shields.io/badge/dcc-2.3.169-brightgreen.svg?style=for-the-badge)](https://www.dcc-servers.net/dcc/)
[![Generic badge](https://img.shields.io/badge/pyzor-1.0.0--6-brightgreen.svg?style=for-the-badge)](https://www.pyzor.org/en/latest/index.html)
[![Generic badge](https://img.shields.io/badge/razor-2.85--9-brightgreen.svg?style=for-the-badge)](https://de.wikipedia.org/wiki/Vipul%E2%80%99s_Razor)


## Configuration:

Each account config file must be a valid json file like the .example file located in /accounts/.
The following configurations are supported:

| Variable      | Req. / Opt. | Default | Description                                                                                                                                                                                                                                   |
|---------------|-------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| server        | required    |         | Your mail server address                                                                                                                                                                                                                      |
| username      | required    |         | your username for logging into your mailaccount                                                                                                                                                                                               |
| password      | required    |         | your password for logging in                                                                                                                                                                                                                  |
| spamHandling  | optional    | yes     | This Flag defines if the given spam filter should be used on the account, e.g. if only old mails should be deleted                                                                                                                            |
| isGmail       | optional    | no      | Gmail has a few unique ways that they interact with a mail client. isbg must be considered to be a client due to interacting with the Gmail servers over IMAP, and thus, should conform to these special requirements for proper integration. |
| spamSubject   | optional    |         | Messages with this prefix will automatically sorted to spam without scoring them, useful if your mailbox provider is offering this feature                                                                                                    |
| report        | optional    | no      | Flag whether or not the `--noreport` for isbg should be set or not. yes = Flag is not set, no (Default) = Flag is set                                                                                                                         |
| spamLifetime  | optional    |         | Duration in days after which the spam-messages in your spambox should be automatically deleted                                                                                                                                                |
| mailLifetime  | optional    |         | Duration in days after which the INBOX-messages should be automatically deleted                                                                                                                                                               |
| folders.inbox | required    |         | Name of your inbox folder / mailbox. You might want to run the container with `LIST_FOLDERS` set to either `true` or `only` first to identify this.                                                                                           |
| folders.spam  | required    |         | Name of your spam folder.                                                                                                                                                                                                                     |
| folders.ham   | optional    |         | Ham folder where you can move wrong spam detections. Spamassassin will learn these in the next learning run as ham. Messages placed here will automatically be moved in your inbox after they have been learned.                              |
| folders.sent  | optional    |         | Your mailbox for sent messages. Spamassassin will use this folder to learn ham messages.                                                                                                                                                      |

## Variables:

The following Docker Environment Variables can be set:


| Variable          | Default                | Description                                                                                                         |
|-------------------|------------------------|---------------------------------------------------------------------------------------------------------------------|
| CRON_HOUR         | 1                      | hour for daily spam learning                                                                                        |
| CRON_MINUTE       | 30                     | minute for daily spam learning                                                                                      |
| TZ                | UTC                    | time zone                                                                                                           |
| USERNAME          | debian-spamd           | username to run spammassin-daemon                                                                                   |
| HAM_BATCH_SIZE    | 50                     | max amount of ham messages to learn per learning run                                                                |
| SPAM_BATCH_SIZE   | 50                     | max amount of spam messages to learn per learning run                                                               |
| FILTER_BATCH_SIZE | 50                     | max amount of messages to filter per run                                                                            |
| MAX_MAIL_SIZE     | 120000                 | mails bigger than this size will be skipped by SA. (BYTES)                                                          |
| EXTRA_OPTIONS     | --nouser-config        | additional options for spamasssassin                                                                                |
| PYZOR_SITE        | public.pyzor.org:24441 | pyzor URI                                                                                                           |
| DETAILED_LOGGING  | false                  | enables verbose logging of isbg/SA                                                                                  |
| LIST_FOLDERS      | false                  | Print list of mailboxes and folders on startup. Settings this to "only" will terminate the container after listing. |
| INTERVAL_MINUTES  | 1                      | Interval in minutes in which the spam search should be run                                                          |

## Support

Docker-ISBG is a free docker image powered by other open source. I am not able to provide full support, however if you find any bugs or if you need a new feature you can create an issue.
If you want to support my work you can do this through my ko-fi page:

https://ko-fi.com/dumpname

## License

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](http://perso.crans.org/besson/LICENSE.html)
