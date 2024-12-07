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
        if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then verboseOption = "--verbose" else verboseOption = "" end
        batchSize = os.getenv( "FILTER_BATCH_SIZE" )
        maxMailSize = os.getenv( "MAX_MAIL_SIZE" )
		if ( confLoader.tableHasKey( config, "spamSubject" ) ) then
			local spamMessages = imapObj.INBOX:contain_subject( config.spamSubject )
			imapObj.INBOX:move_messages( imapObj[config.folders.spam], spamMessages )
			if (spamMessages==nil)or(#spamMessages==0) then
				print( "0 spams moved to learn" )		
			end
		end
		local report = "--noreport"
		if ( confLoader.tableHasKey( config, "report" ) and config.report=="yes") then
			report = ""
		end
		if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
            print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --spamc --imapuser " .. config.username .. "  --partialrun " .. batchSize .. " --maxsize " .. maxMailSize .." " .. report .. " --delete --expunge --spaminbox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " " .. verboseOption .. " \" $USERNAME" )
        end
		os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --spamc --imapuser " .. config.username .. " --partialrun " .. batchSize .. " --maxsize " .. maxMailSize .." " .. report .. " --delete --expunge --spaminbox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " " .. verboseOption .. " \" $USERNAME" )
	end
end
