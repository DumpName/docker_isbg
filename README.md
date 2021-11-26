# This is a Docker Image for the Tool isbg
Docker container that uses [isbg](https://gitlab.com/isbg/isbg) and [isbg](https://github.com/lefcha/imapfilter) to filter out spam from a remote IMAP server.
The Docker Image is based on [Debians slim Stable Image](https://hub.docker.com/_/debian).

Configuration: There are 2 volumes, their content is initialized during container startup:

    /home/spamassassin/.spamassassin : holds the SpamAssassin data files, to keep them between container resets.
    /home/spamassassin/accounts : holds the IMAP accounts configuration.

To configure your IMAP accounts, create a new .conf file in the /accounts volume for each imap account that you want to be filtered. The files are JSON files, see the explanation below to learn about mandatory and optional parameters.

The container runs a learning process on startup, so do not leave a configuration with a huge email directory active if you want the container to start in a reasonnable time.

**Note: As this image stores needs to store your _password in cleartext_ you should only use it in an environment that you fully trust!** Be aware of the risk that this involves!

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
