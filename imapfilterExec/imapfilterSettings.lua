local settings = {}

settings.configFolder = "/var/lib/mailaccounts/"
settings.isbgPath = "isbg"
settings.default = {}
settings.default.batchSize = {}
settings.default.batchSize.ham = 50
settings.default.batchSize.spam = 50
settings.default.batchSize.filter = 50

return settings
