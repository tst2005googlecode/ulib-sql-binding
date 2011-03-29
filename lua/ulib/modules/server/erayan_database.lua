-- database things in here
require("mysqloo")
--[[ erayan_config ]]--
local erayan_config = {
	hostname = "erayan.eu";
	username = "dehaantj_ulibulx";
	password = "tub561vihis3";
	database = "dehaantj_ulib_ulx";
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
	-- Log (insert)
	['insert_log'] = "INSERT INTO `ulxlog` (`ulxLogTimeStamp`, `ulxLogContent`, `ulxLogServer`) VALUES (NOW(), '%s', '%s')";
	-- Users (insert, select, update)
	['insert_user'] = "INSERT INTO `ulibuser` "..
	"(`ulibUserSteamID`, `ulibUserName`, `ulibUserGroupID`, `ulibUserLastVisited`, `ulibUserFirstVisited`, `ulibUserTimesVisited`, `ulibUserLastUsedIP`, `ulibUserFirstUsedIP`, `ulibUserServer`)"..
	" VALUES ('%s', '%s', 0, NOW(), NOW(), 1, '%s', '%s', '%s');";
	['select_user'] = "SELECT *, COUNT(*) AS Hits FROM `ulibuser` WHERE ulibUserSteamID = '%s' AND ulibUserServer = '%s' LIMIT 1;";
	['update_user'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserTimesVisited`=`ulibUserTimesVisited`+1, `ulibUserLastUsedIP`='%s' WHERE `ulibUserID`=%i;";
	['update_user_2'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserFrags`=`ulibUserFrags`+%i,`ulibUserDeaths`=`ulibUserDeaths`+%i WHERE `ulibUserSteamID`='%s';";
	-- Groups
	['select_group_list'] = "SELECT * FROM `ulcgroup` WHERE `ulibGroupServer` = '%s' ";
	['select_group'] = "SELECT * FROM `uclgroup` WHERE `ulibGroupID` = '%i' ";
	['insert_group'] = "INSERT INTO `dehaantj_ulib_ulx`.`ulibgroup` (`ulibGroupName`, `ulibGroupInheritFromID`, `ulibGroupServer`, `ulibGroupDisplayName`, `ulibGroupCanTarget`) VALUES ('%s', %i, '%s', '%s', '%s');";
	-- Permissions
	['insert_permission'] = "INSERT INTO `uclpermission` () VALUES ()";
	['select_permission_user'] = "SELECT * FROM `uclpermission` WHERE `uclPermissionID` = %i";
	['delete_permission'] = "DELETE FROM `uclpermission` WHERE `uclPermissionID` = %i";
	['delete_permission_user'] = "DELETE FROM `uclpermission` WHERE `uclPermissionUserID` = '%s'";
}

local function blankCallback() end
local notifyerror, notifymessage
local addLogOnSuccess, addLogOnFailure
local doConnect, databaseOnFailure, databaseOnConnected
local pendingOnFailure, pendingOnSuccess
local getIP, cleanIP
local doAddUser, addUserOnFailure, addUserOnSuccess
local doCheckUser, checkUserOnFailure, checkUserOnSuccess, checkUserOnData
local doUpdateUser, updateUserOnFailure, updateUserOnSuccess
local doUpdateUser2, updateUser2OnFailure, updateUser2OnSuccess
local doAddGroup, addGroupOnFailure, addGroupOnSuccess

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

include('../../../erayan/erayan_logs.lua');

include('../../../erayan/erayan_users.lua');

include('../../../erayan/erayan_groups.lua');

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

hook.Add( "PlayerDisconnected", "EraYaNPlayerDisconnected", doUpdateUser2 )
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

