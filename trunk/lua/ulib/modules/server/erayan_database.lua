-- database things in here
require("mysqloo")

if not erayan then
	include('./erayan/erayan_init.lua');
end

erayan.database = {}

-- The mysqloo ones are descriptive, but a mouthful.
STATUS_READY	= mysqloo.DATABASE_CONNECTED
STATUS_WORKING	= mysqloo.DATABASE_CONNECTING
STATUS_OFFLINE	= mysqloo.DATABASE_NOT_CONNECTED
STATUS_ERROR	= mysqloo.DATABASE_INTERNAL_ERROR


erayan.queries = {
	-- Log (insert)
	['insert_log'] = "INSERT INTO `ulxlog` (`ulxLogTimeStamp`, `ulxLogContent`, `ulxLogServer`) VALUES ('%s', '%s', '%s')";
	-- Users (insert, select, update)
	['insert_user'] = "INSERT INTO `ulibuser` "..
	"(`ulibUserSteamID`, `ulibUserName`, `ulibUserGroupID`, `ulibUserLastVisited`, `ulibUserFirstVisited`, `ulibUserTimesVisited`, `ulibUserLastUsedIP`, `ulibUserFirstUsedIP`, `ulibUserServer`)"..
	" VALUES ('%s', '%s', 0, NOW(), NOW(), 1, '%s', '%s', '%s');";
	['select_user'] = "SELECT *, COUNT(*) AS Hits FROM `ulibuser` WHERE ulibUserSteamID = '%s' AND ulibUserServer = '%s' LIMIT 1;";
	['update_user'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserTimesVisited`=`ulibUserTimesVisited`+1, `ulibUserLastUsedIP`='%s' WHERE `ulibUserID`=%i;";
	['update_user_2'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserFrags`=`ulibUserFrags`+%i,`ulibUserDeaths`=`ulibUserDeaths`+%i WHERE `ulibUserSteamID`='%s';";
	-- Groups
	['select_group_list'] = "SELECT *  FROM `ulibgroup` WHERE `ulibGroupServer` = '%s' ";
	['select_group'] = "SELECT *, COUNT(*) AS Hits FROM `ulibgroup` WHERE `ulibGroupName` = '%s' AND `ulibGroupServer` = '%s' LIMIT 1;";
	['insert_group'] = "INSERT INTO `ulibgroup` (`ulibGroupName`, `ulibGroupInheritFrom`, `ulibGroupServer`, `ulibGroupDisplayName`, `ulibGroupCanTarget`) VALUES ('%s', '%s', '%s', '%s', '%s');";
	['update_group'] = "UPDATE `dehaantj_ulib_ulx`.`ulibgroup` SET `ulibGroupInheritFrom`='%s', `ulibGroupServer`='%s', `ulibGroupDisplayName`='%s', `ulibGroupCanTarget`='%s' WHERE `ulibGroupID`=%i;";
	-- Permissions
	['insert_permission'] = "INSERT INTO `ulibpermission` () VALUES ()";
	['select_permission_user'] = "SELECT * FROM `ulibpermission` WHERE `uclPermissionID` = %i";
	['delete_permission'] = "DELETE FROM `ulibpermission` WHERE `uclPermissionID` = %i";
	['delete_permission_user'] = "DELETE FROM `ulibpermission` WHERE `uclPermissionUserID` = '%s'";
}

local function blankCallback() end
--[[
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
]]--

-- functions
function erayan.cleanIP(ip)
	return string.match(ip, "(%d+%.%d+%.%d+%.%d+)");
end
function erayan.getIP(ply)
	return erayan.cleanIP(ply:IPAddress());
end


function erayan.notifyerror(...)
	ErrorNoHalt("[", os.date(), "][erayan_database.lua] ", ...)
	print()
end
function erayan.notifymessage(...)
	local words = table.concat({"[",os.date(),"][erayan_database.lua] ",...},"").."\n"
	ServerLog(words)
	Msg(words)
end

function erayan.doConnect()	
	erayan.database = mysqloo.connect(erayan.config.hostname, erayan.config.username, erayan.config.password, erayan.config.database, erayan.config.portnumb)
	erayan.database.onConnectionFailed = erayan.databaseOnFailure
	erayan.database.onConnected = erayan.databaseOnConnected
	erayan.database.pending = {}
	erayan.database:connect()
end

include('./erayan/erayan_logs.lua');

include('./erayan/erayan_users.lua');

include('./erayan/erayan_groups.lua');

function erayan.pendingOnFailure(self, err)
	notifyerror( 'Pending SQL could\'t execute',err )
end

function erayan.pendingOnSuccess()
	print( 'EraYaN: ', '-----------------------Processed pending query----------------------- ')
end

function erayan.databaseOnFailure(self, err)
	notifyerror( 'SQL Connect fail ',err  )
end
function erayan.databaseOnConnected(self)
	print( 'EraYaN: ','-----------------------Connected to DB-----------------------')
	if (#self.pending == 0) then return; end
	
	print( 'EraYaN: ', #self.pending, 'pending queries to do.')
	local query;
	for _, info in pairs(self.pending) do
		query 			= self:query(info[1]);
		query.onFailure	= erayan.pendingOnFailure;
		query.onSuccess	= erayan.pendingOnSuccess;
		query:start();
	end
	self.pending = {};

end

--concommands
	

function erayan.fEraYaNStatus( player, command, arguments )
    print('EraYaN: Status', erayan.database:status())
end
 
concommand.Add( "erayan_status", erayan.fEraYaNStatus )

-- Hooks
do
local function ShutDown()
		if (erayan.database) then
			erayan.database:abortAllQueries()
		end
	end

hook.Add("ShutDown", "EraYaNDBShutdown", ShutDown)

hook.Add( "PlayerDisconnected", "EraYaNPlayerDisconnected", erayan.doUpdateUser2 )
end

-- Checks the status of the database and recovers if there are errors
-- WARNING: This function erayan.is blocking. It is auto-called every 5 minutes.
function erayan.CheckStatus()
	if (not erayan.database or erayan.database.automaticretry) then return end
	local status = erayan.database:status()
	if (status == STATUS_WORKING or status == STATUS_READY) then
		return
	elseif (status == STATUS_ERROR) then
		erayan.notifyerror("The database object has suffered an inernal error and will be recreated.")
		local pending = erayan.database.pending
		erayan.doConnect()
		erayan.database.pending = pending
	else
		erayan.notifyerror("The server has lost connection to the database. Retrying...")
		erayan.database:connect()
	end
end
timer.Create("EraYaN-Status-Checker", 300, 0, erayan.CheckStatus)

erayan.doConnect()

