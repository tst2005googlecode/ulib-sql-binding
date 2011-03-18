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
	['check_user'] = "SELECT *, COUNT(*) AS Hits FROM `ulib-ulx`.`ulibuser` WHERE ulibUserSteamID = '%s' LIMIT 1;";
	['update_user'] = "UPDATE `ulib-ulx`.`ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserTimesVisited`=`ulibUserTimesVisited`+1, `ulibUserLastUsedIP`='%s', `ulibUserServers`=%s WHERE `ulibUserID`=%i;"


}

local function blankCallback() end
local notifyerror, notifymessage
local addLogOnSuccess, addLogOnFailure
local doConnect, databaseOnFailure, databaseOnConnected
local pendingOnFailure, pendingOnSuccess
local getIP, cleanIP
local doAddUser, addUserOnFailure, addUserOnSuccess
local doUpdateUser, updateOnFailure, updateOnSuccess

-- functions
function cleanIP(ip)
	return string.match(ip, "(%d+%.%d+%.%d+%.%d+)");
end
function getIP(ply)
	return cleanIP(ply:IPAddress());
end


function notifyerror(...)
	ErrorNoHalt("[", os.date(), "][erayan_database.lua] ", ...)
	print()
end
function notifymessage(...)
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
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addLogOnFailure
		query.onSuccess = addLogOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Added Log Item-----------------------')
	else
		table.insert(database.pending, {queryText, str})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Log Query Pending-----------------------')
	end

	end
end

function addLogOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function addLogOnSuccess()
	print( 'EraYaN: ', '-----------------------Added Log Item----------------------- ')
end

function doAddUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['insert_user']:format(ply:SteamID(),ply:GetName(),getIP(ply),getIP(ply),erayan_config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addUserOnFailure
		query.onSuccess = addUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Add User Query Pending-----------------------')
	end

	end
end

function addUserOnFailure(self, err)
	notifyerror( 'SQL Add User Fail ',err )
end

function addUserOnSuccess()
	print( 'EraYaN: ', '-----------------------Added User----------------------- ')
end

function doCheckUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['check_user']:format(ply:SteamID(),'%'..erayan_config.server..'%')
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = checkUserOnFailure
		query.onSuccess = checkUserOnSuccess
		query.onData = checkUserOnData
		query.ply = ply
		query:start()
		print( 'EraYaN: ','-----------------------Checking User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Check User Query Pending-----------------------')
	end

	end
end

function checkUserOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function checkUserOnSuccess()
	print( 'EraYaN: ', '-----------------------Checked User----------------------- ')
end

function checkUserOnData(self, datarow)
	print( 'EraYaN: ','-----------------------Recieved User Data----------------------- ')
	print( 'EraYaN: ','DataRow', datarow['Hits'])
	if self.ply:IsBot() then 
		print( 'EraYaN: ','-----------------------We dont want bots in our DB----------------------- ')
		return 0
	end
	print( 'EraYaN: ',type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits']  == "0" then
		print( 'EraYaN: ','-----------------------Adding...----------------------- ')
		doAddUser(self.ply)
		else
		-- update info
		local servers
		if string.find( datarow['ulibUserServers'], erayan_config.server, 0, true ) then
			servers = "CONCAT_WS(',','ulibUserServers')"
		else
			servers = "CONCAT_WS(',',ulibUserServers,'TTT')"
		end
		doUpdateUser(self.ply, servers, datarow['ulibUserID'])
	end
end

function doUpdateUser(ply, servers, id)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['update_user']:format(ply:GetName(), getIP(ply), servers, id)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = updateUserOnFailure
		query.onSuccess = updateUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Update User Query Pending-----------------------')
	end

	end
end

function updateUserOnFailure(self, err)
	notifyerror( 'SQL Update User Fail ',err )
end

function updateUserOnSuccess()
	print( 'EraYaN: ', '-----------------------Updated User----------------------- ')
end

function  pendingOnFailure(self, err)
	notifyerror( 'Pending SQL could\'t execute',err )
end

function  pendingOnSuccess()
	print( 'EraYaN: ', '-----------------------Processed pending query----------------------- ')
end

function databaseOnFailure(self, err)
	notifyerror( 'SQL Connect fail ',err  )
end
function databaseOnConnected(self)
	print( 'EraYaN: ','-----------------------Connected to DB-----------------------')
	if (#self.pending == 0) then return; end
	
	print( 'EraYaN: ', #self.pending, 'pending queries to do.')
	local query;
	for _, info in pairs(self.pending) do
		query 			= self:query(info[1]);
		query.onFailure	= pendingOnFailure;
		query.onSucces	= pendingOnSucces;
		query:start();
	end
	self.pending = {};

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

