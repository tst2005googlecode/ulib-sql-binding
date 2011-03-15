-- database things in here
require("mysqloo")
--[[ erayan_config ]]--
local erayan_config = {
	hostname = ".";
	username = "root";
	password = "de341h1aa9n";
	database = "ulib-ulx";
	website  = "blackbox.erayan.eu";
	portnumb = 3306;
	server = "TTT";
}

local database

-- The mysqloo ones are descriptive, but a mouthful.
STATUS_READY	= mysqloo.DATABASE_CONNECTED
STATUS_WORKING	= mysqloo.DATABASE_CONNECTING
STATUS_OFFLINE	= mysqloo.DATABASE_NOT_CONNECTED
STATUS_ERROR	= mysqloo.DATABASE_INTERNAL_ERROR


local queries = {
	-- Log
	['insert_log'] = "INSERT INTO `ulxlog` (`ulxLogTimeStamp`, `ulxLogContent`, `ulxLogServer`) VALUES (NOW(), '%s', '%s')";
	-- Users
	['insert_user'] = "INSERT INTO `ulib-ulx`.`ulibuser` "..
	"(`ulibUserSteamID`, `ulibUserName`, `ulibUserGroupID`, `ulibUserLastVisited`, `ulibUserFirstVisited`, `ulibUserTimesVisited`, `ulibUserLastUsedIP`, `ulibUserFirstUsedIP`, `ulibUserServers`)"..
	" VALUES ('%s', '%s', 0, NOW(), NOW(), 1, '%s', '%s', 'TTT');";
	['check_user'] = "SELECT COUNT(*) AS Hits FROM `ulib-ulx`.`ulibuser` WHERE ulibUserSteamID = '%s' AND ulibUserServers LIKE \'%s'\;"
}

local function blankCallback() end
local notifyerror, notifymessage
local addLogOnSuccess, addLogOnFailure
local doConnect, databaseOnFailure, databaseOnConnected
local pendingOnFailure, pendingOnSuccess
local getIP
local doAddUser, addUserOnFailure, addUserOnSuccess
-- functions
local function notifyerror(...)
	ErrorNoHalt("[", os.date(), "][erayan_database.lua] ", ...)
	print()
end
local function notifymessage(...)
	local words = table.concat({"[",os.date(),"][erayan_database.lua] ",...},"").."\n"
	ServerLog(words)
	Msg(words)
end

function doConnect()	
	database = mysqloo.connect(erayan_config.hostname, erayan_config.username, erayan_config.password, erayan_config.database, erayan_config.portnumb)
	database.onConnectionFailed = databaseOnFailure
	database.onConnected = databaseOnConnected
	database.pending = {}
	database:connect()
end

function doAddLogItem(str)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['insert_log']:format(str,erayan_config.server)
		-- print('Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addLogOnFailure
		query.onSuccess = addLogOnSuccess
		query:start()
		---- print('-----------------------Added Log Item-----------------------')
	else
		table.insert(database.pending, {queryText, str})
		CheckStatus()
		-- print('-----------------------Log Query Pending-----------------------')
	end

	end
end

function addLogOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function addLogOnSuccess()
	-- print( '-----------------------Added Log Item----------------------- ')
end

function doAddUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['insert_user']:format(ply:SteamID(),ply:GetName(),getIP(ply),getIP(ply),erayan_config.server)
		-- print('Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addUserOnFailure
		query.onSuccess = addUserOnSuccess
		query:start()
		---- print('-----------------------Added User-----------------------')
	else
		table.insert(database.pending, {queryText, str})
		CheckStatus()
		-- print('-----------------------User Query Pending-----------------------')
	end

	end
end

function addUserOnFailure(self, err)
	notifyerror( 'SQL Add User Fail ',err )
end

function addUserOnSuccess()
	print( '-----------------------Added User----------------------- ')
end

function doCheckUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['check_user']:format(ply:SteamID(),'%'..erayan_config.server..'%')
		-- print('Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = checkUserOnFailure
		query.onSuccess = checkUserOnSuccess
		query.onData = checkUserOnData
		query.ply = ply
		query:start()
		---- print('-----------------------Added User-----------------------')
	else
		table.insert(database.pending, {queryText, str})
		CheckStatus()
		-- print('-----------------------User Query Pending-----------------------')
	end

	end
end

function checkUserOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function checkUserOnSuccess()
	-- print( '-----------------------Checked User----------------------- ')
end

function checkUserOnData(self, datarow)
	print('-----------------------Recieved User Data----------------------- ')
	print('DataRow', datarow['Hits'])
	if self.ply:IsBot() then 
		print('-----------------------We dont want bots in our DB----------------------- ')
		return 0
	end
	print(type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits'] == 0 then
		print('-----------------------Adding...----------------------- ')
		doAddUser(self.ply)
	end
end

function  pendingOnFailure(self, err)
	notifyerror( 'Pending SQL could\'t execute',err )
end

function  pendingOnSuccess()
	-- print( '-----------------------Processed pending query----------------------- ')
end

function databaseOnFailure(self, err)
	notifyerror( 'SQL Connect fail ',err  )
end
function databaseOnConnected(self)
	-- print('-----------------------Connected to DB-----------------------')
	if (#self.pending == 0) then return; end
	
	-- print( #self.pending, 'pending queries to do.')
	local query;
	for _, info in pairs(self.pending) do
		query 			= self:query(info[1]);
		query.str	= info[2];
		query.onFailure	= pendingOnFailure;
		query.onSucces	= pendingOnSucces;
		query:start();
	end
	self.pending = {};

end

local function getIP(ply)
	return cleanIP(ply:IPAddress());
end


-- Hooks
do
local function ShutDown()
		if (database) then
			database:abortAllQueries()
		end
	end

hook.Add("ShutDown", "EraYaNDBShutdown", ShutDown)
end

-- Checks the status of the database and recovers if there are errors
-- WARNING: This function is blocking. It is auto-called every 5 minutes.
function CheckStatus()
	if (not database or database.automaticretry) then return end
	local status = database:status()
	if (status == STATUS_WORKING or status == STATUS_READY) then
		return
	elseif (status == STATUS_ERROR) then
		notifyerror("The database object has suffered an inernal error and will be recreated.")
		local pending = database.pending
		doConnect()
		database.pending = pending
	else
		notifyerror("The server has lost connection to the database. Retrying...")
		database:connect()
	end
end
timer.Create("EraYaN-Status-Checker", 300, 0, CheckStatus)

doConnect()

