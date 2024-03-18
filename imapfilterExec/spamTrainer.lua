confLoader = require "confLoader"
settings = require "imapfilterSettings"

--os.execute( "sudo /usr/sbin/logrotate -s ~/.logrotate/status ~/isbg-exec/logrotate" )

conftab = confLoader.scandir( settings.configFolder )
print ( "SpamTrainer Found " ..#conftab .." Config Files!" )

for i, confFile in ipairs( conftab ) do
	local config = confLoader.readConf( confFile )
	if config ~= nil then
		print( "Training Spam for "..confFile )
		local imapObj = IMAP {
			server = config.server,
			username = config.username,
			password = config.password,
			ssl = "ssl3"
		}
		if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then verboseOption = " --verbose" else verboseOption = "" end
		if( confLoader.tableHasKey( config, "isGmail" ) and config.isGmail == "yes" ) then gmailOption = " --gmail" else gmailOption = "" end
		batchSize = os.getenv( "SPAM_BATCH_SIZE" )
		maxMailSize = os.getenv( "MAX_MAIL_SIZE" )
		if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
            print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun " .. batchSize .. " --learnspambox " .. config.folders.spam .. " --passwdfilename " .. confFile .. verboseOption .. gmailOption .. " \" $USERNAME" )
		end
		os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun  " .. batchSize .. " --learnspambox " .. config.folders.spam .. " --passwdfilename " .. confFile  .. verboseOption .. gmailOption ..  " \" $USERNAME"  )
        batchSize = os.getenv( "HAM_BATCH_SIZE" )
        if ( confLoader.tableHasKey( config.folders, "ham" ) ) then
			if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
                print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun " .. batchSize .. " --learnhambox " .. config.folders.ham .. " --passwdfilename " .. confFile  .. verboseOption .. gmailOption ..  " \" $USERNAME" )
			end
			os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun " .. batchSize .. " --learnhambox " .. config.folders.ham .. " --passwdfilename " .. confFile  .. verboseOption .. gmailOption ..  " \" $USERNAME" )
			local hamMessages = imapObj[config.folders.ham]:select_all()
			hamMessages:move_messages( imapObj[config.folders.inbox] )
			print( #hamMessages.." hams moved" )
		end
		if ( confLoader.tableHasKey( config.folders, "sent" ) ) then
            if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
                print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun " .. batchSize .. " --learnhambox " .. config.folders.sent .. " --passwdfilename " .. confFile  .. verboseOption .. gmailOption ..  " \" $USERNAME" )
			end
			os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize " .. maxMailSize .. " --partialrun " .. batchSize .. " --learnhambox " .. config.folders.sent .. " --passwdfilename " .. confFile  .. verboseOption .. gmailOption ..  " \" $USERNAME" )
		end
		if ( confLoader.tableHasKey( config, "spamLifetime" ) ) then
			local spamMessages = imapObj[config.folders.spam]:is_older( config.spamLifetime )
			if( confLoader.tableHasKey( config, "isGmail" ) and config.isGmail ) then
			    imapObj[config.folders.inbox]:move_messages( imapObj["[Gmail]/Trash"], spamMessages )
			else
                spamMessages:delete_messages( )
			end
			print( #spamMessages.. " spams deletetd" )
		end
	end
end
