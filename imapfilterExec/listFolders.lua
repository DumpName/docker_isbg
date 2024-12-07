local confLoader = require "confLoader"

conftab = confLoader.scandir( "~/isbg-config/" )
print ( "Found " ..#conftab .." Config Files!" )

for i, confFile in ipairs( conftab ) do
	local config = confLoader.readConf( confFile )
	if config ~= nil then
		local imapObj = IMAP {
			server = config.server,
			username = config.username,
			password = config.password,
		}
		mailboxes, folders = imapObj:list_all()
		print("Mailbox "..#config.username.."@"..#config.server.." contains:")
		print("######MAILBOXES######")
		for _, m in ipairs(mailboxes) do print(m) end
		print("#######FOLDERS#######")
		for _, f in ipairs(folders) do print(f) end
	end
end
