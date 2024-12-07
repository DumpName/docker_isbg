local json = require "dkjson"

local model = {}

function model.scandir(dirname)
        callit = os.tmpname()
        os.execute("ls -1 "..dirname .. "*.conf >"..callit)
        f = io.open(callit,"r")
        rv = f:read("*all")
        f:close()
        os.remove(callit)

        tabby = {}
        local from  = 1
        local delim_from, delim_to = string.find( rv, "\n", from  )
        while delim_from do
                table.insert( tabby, string.sub( rv, from , delim_from-1 ) )
                from  = delim_to + 1
                delim_from, delim_to = string.find( rv, "\n", from  )
        end
        -- table.insert( tabby, string.sub( rv, from  ) )
        -- Comment out eliminates blank line on end!
        return tabby
end

function model.readConf( filepath )
        local file = assert( io.open( filepath, "rb" ) )
        local content = file:read( "*all" )
        file:close( )
        local jsonConfig = {}
        if content ~= nil then
                jsonConfig = json.decode( content )
                if jsonConfig == nil then
                print("json format error from file:"..filepath)
                end
        end
        return jsonConfig
end

function model.tableHasKey( tab, key )
        return tab[ key ] ~= nil
end

function model.accounts( )
	conftab = model.scandir("/root/imapfilter/")
	print ( "Found " ..#conftab .." Config Files!" )
	local accounts = {}
	local acc = 0

	for i, confFile in ipairs( conftab ) do
        	local conf = model.readConf( confFile )
        	if conf ~= nil then
                	local imapObj = IMAP {
                	        server = conf.server,
                        	username = conf.username,
                        	password = conf.password,
                	}
               		accounts[acc] = { config = conf, imap = imapObj }
                	acc = acc + 1
        	end
	end
	return accounts
end

return model
