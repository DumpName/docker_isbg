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
		batchSize = settings.default.batchSize.spam
		if ( confLoader.tableHasKey( config, "batchSize" ) and confLoader.tableHasKey( config.batchSize, "spam" ) ) then
            batchSize = config.batchSize.spam
        end
		print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize 512000 --partialrun " .. batchSize .. " --learnspambox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
		os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize 512000 --partialrun  " .. batchSize .. " --learnspambox " .. config.folders.spam .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME"  )
        batchSize = settings.default.batchSize.ham
		if ( confLoader.tableHasKey( config, "batchSize" ) and confLoader.tableHasKey( config.batchSize, "ham" ) ) then
            batchSize = config.batchSize.ham
        end
        if ( confLoader.tableHasKey( config.folders, "ham" ) ) then
			print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize 512000 --partialrun " .. batchSize .. " --learnhambox " .. config.folders.ham .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
			os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --maxsize 512000 --partialrun " .. batchSize .. " --learnhambox " .. config.folders.ham .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
			local hamMessages = imapObj[config.folders.ham]:select_all()
			hamMessages:move_messages( imapObj.INBOX )
			print( #hamMessages.." hams moved" )
		end
		if ( confLoader.tableHasKey( config.folders, "sent" ) ) then
			print( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --partialrun " .. batchSize .. " --learnhambox " .. config.folders.sent .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
			os.execute( "su -c \"" .. settings.isbgPath .. " --imaphost " .. config.server .. " --imapuser " .. config.username .. " --spamc --teachonly --partialrun " .. batchSize .. " --learnhambox " .. config.folders.sent .. " --passwdfilename " .. confFile .. " --verbose \" $USERNAME" )
		end
		if ( confLoader.tableHasKey( config, "spamLifetime" ) ) then
			local spamMessages = imapObj[config.folders.spam]:is_older( config.spamLifetime )
			spamMessages:delete_messages( )
			print( #spamMessages.. " spams deletetd" )
		end
	end
end
