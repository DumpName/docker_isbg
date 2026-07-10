confLoader = require "confLoader"
settings = require "imapfilterSettings"

--os.execute( "sudo /usr/sbin/logrotate -s ~/.logrotate/status ~/isbg-exec/logrotate" )

conftab = confLoader.scandir( settings.configFolder )
print ( "SpamTrainer Found " ..#conftab .." Config Files!" )

for i, confFile in ipairs( conftab ) do
	local config = confLoader.readConf( confFile )
	print( "Handling config file " .. i );
	if config ~= nil then
		local imapObj = IMAP {
			server = config.server,
			username = config.username,
			password = config.password,
			ssl = "ssl3"
		}
		if ( ( not confLoader.tableHasKey( config, "spamHandling" ) ) or config.spamHandling == "yes" ) then
			print( "Training Spam for "..confFile )
			verboseOption = confLoader.getVerboseOption( )
			gmailOption = confLoader.getGmailOption( config )
			batchSize = os.getenv( "SPAM_BATCH_SIZE" )
			maxMailSize = os.getenv( "MAX_MAIL_SIZE" )
			if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
				print( "su -c \"" .. settings.isbgPath
						.. " --imaphost " .. confLoader.escape_for_shell( config.server )
						.. " --imapuser " .. confLoader.escape_for_shell( config.username )
						.. " --spamc --teachonly --maxsize " .. maxMailSize
						.. " --partialrun " .. batchSize ..
						" --learnspambox " .. confLoader.escape_for_shell( config.folders.spam )
						.. " --passwdfilename " .. confFile
						.. verboseOption
						.. gmailOption
						.. " \" $USERNAME" )
			end
			os.execute( "su -c \"" .. settings.isbgPath
						.. " --imaphost " .. confLoader.escape_for_shell( config.server )
						.. " --imapuser " .. confLoader.escape_for_shell( config.username )
						.. " --spamc --teachonly --maxsize " .. maxMailSize
						.. " --partialrun  " .. batchSize
						.. " --learnspambox " .. confLoader.escape_for_shell(config.folders.spam )
						.. " --passwdfilename " .. confFile
						.. verboseOption
						.. gmailOption
						.. " \" $USERNAME"  )
			batchSize = os.getenv( "HAM_BATCH_SIZE" )
			if ( confLoader.tableHasKey( config.folders, "ham" ) ) then
				if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
					print( "su -c \"" .. settings.isbgPath
							.. " --imaphost " .. confLoader.escape_for_shell( config.server )
							.. " --imapuser " .. confLoader.escape_for_shell( config.username )
							.. " --spamc --teachonly --maxsize " .. maxMailSize
							.. " --partialrun " .. batchSize
							.. " --learnhambox " .. confLoader.escape_for_shell(config.folders.ham )
							.. " --passwdfilename " .. confFile
							.. verboseOption
							.. gmailOption
							.. " \" $USERNAME" )
				end
				os.execute( "su -c \"" .. settings.isbgPath
							.. " --imaphost " .. confLoader.escape_for_shell( config.server )
							.. " --imapuser " .. confLoader.escape_for_shell( config.username )
							.. " --spamc --teachonly --maxsize " .. maxMailSize
							.. " --partialrun " .. batchSize
							.. " --learnhambox " .. confLoader.escape_for_shell( config.folders.ham )
							.. " --passwdfilename " .. confFile
							.. verboseOption
							.. gmailOption
							.. " \" $USERNAME" )
				local hamMessages = imapObj[ config.folders.ham ]:select_all( )
				hamMessages:move_messages( imapObj[ config.folders.inbox ] )
				print( #hamMessages.." hams moved" )
			end
			if ( confLoader.tableHasKey( config.folders, "sent" ) ) then
				if( os.getenv( "DETAILED_LOGGING" ) == "true" ) then
					print( "su -c \"" .. settings.isbgPath
							.. " --imaphost " .. confLoader.escape_for_shell( config.server )
							.. " --imapuser " .. confLoader.escape_for_shell( config.username )
							.. " --spamc --teachonly --maxsize " .. maxMailSize
							.. " --partialrun " .. batchSize
							.. " --learnhambox " .. confLoader.escape_for_shell( config.folders.sent )
							.. " --passwdfilename " .. confFile
							.. verboseOption
							.. gmailOption
							.. " \" $USERNAME" )
				end
				os.execute( "su -c \"" .. settings.isbgPath
							.. " --imaphost " .. confLoader.escape_for_shell( config.server )
							.. " --imapuser " .. confLoader.escape_for_shell( config.username )
							.. " --spamc --teachonly --maxsize " .. maxMailSize
							.. " --partialrun " .. batchSize
							.. " --learnhambox " .. confLoader.escape_for_shell( config.folders.sent )
							.. " --passwdfilename " .. confFile
							.. verboseOption
							.. gmailOption
							.. " \" $USERNAME" )
			end
			if ( confLoader.tableHasKey( config, "spamLifetime" ) ) then
				local spamMessages = imapObj[ config.folders.spam ]:is_older( config.spamLifetime )
				if( confLoader.tableHasKey( config, "isGmail" ) and config.isGmail == "yes" ) then
					spamMessages:move_messages( imapObj[ "[Gmail]/Trash" ] )
				else
					spamMessages:delete_messages( )
				end
				print( #spamMessages.. " spams deleted" )
			end
		end
		if ( confLoader.tableHasKey( config, "mailLifetime" ) ) then
			local oldMessages = imapObj[ config.folders.inbox ]:is_older( config.mailLifetime )
			if( confLoader.tableHasKey( config, "deleteMail" ) and config.deleteMail == "yes" ) then
				if( confLoader.tableHasKey( config, "isGmail" ) and config.isGmail == "yes" ) then
					oldMessages:move_messages( imapObj[ "[Gmail]/Trash" ], oldMessages )
					print( #oldMessages.. " old mails moved to trash" )
				else
					oldMessages:delete_messages( )
					print( #oldMessages.. " old mails deleted" )
				end
			else
				if ( confLoader.tableHasKey( config.folders, "trash" ) ) then
					oldMessages:move_messages( imapObj[ config.folders.trash ] )
					print( #oldMessages.. " old mails moved to trash" )
				else
					print( "No trash folder defined & deleting messages is not allowed! Could not delete ".. #oldMessages .. " old mails." )
				end
			end
		end
	end
end
