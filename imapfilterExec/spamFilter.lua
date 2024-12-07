confLoader = require "confLoader"
settings = require "imapfilterSettings"

conftab = confLoader.scandir( settings.configFolder )
print ( "Spam Filter found " ..#conftab .." Config Files!" )

for i, confFile in ipairs( conftab ) do
	local config = confLoader.readConf( confFile )
	if config ~= nil then
		local imapObj = IMAP {
			server = config.server,
			username = config.username,
			password = config.password,
			ssl = "ssl3"
		}
		if ( confLoader.tableHasKey( config, "spamSubject" ) ) then
			local spamMessages = imapObj.INBOX:contain_subject( config.spamSubject )
			imapObj.INBOX:move_messages( imapObj[config.folders.spam], spamMessages )
			if (spamMessages==nil)or(#spamMessages==0) then
				print( "0 spams moved to learn" )		
			end
		end
		local mailsToScan = 0
		if ( confLoader.tableHasKey( config, "mailsToScan" ) ) then
			mailsToScan = config.mailsToScan
		end
		local report = "--noreport"
		if ( confLoader.tableHasKey( config, "report" ) and config.report=="yes") then
			report = ""
		end 
		print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. "  --partialrun " .. mailsToScan .. " --maxsize 512000 " .. report .. " --delete --expunge --spaminbox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
		os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --spamc --imapuser " .. config.username .. " --partialrun " .. mailsToScan .. " --maxsize 512000 " .. report .. " --delete --expunge --spaminbox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
	end
end
