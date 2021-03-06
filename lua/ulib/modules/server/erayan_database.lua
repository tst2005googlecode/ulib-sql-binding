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
	" VALUES ('%s', '%s', %s, NOW(), NOW(), %i, '%s', '%s', '%s');";
	['select_user'] = "SELECT *, COUNT(*) AS Hits FROM `ulibuser` WHERE ulibUserSteamID = '%s' AND `ulibUserServer` = '%s' LIMIT 1;";
	['update_user'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserGroupID`=%s, `ulibUserTimesVisited`=`ulibUserTimesVisited`+%i WHERE `ulibUserID`=%i;";
	['update_user_2'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserFrags`=`ulibUserFrags`+%i,`ulibUserDeaths`=`ulibUserDeaths`+%i, `ulibUserTimePlayed`= CASE WHEN (%i-90)>`ulibUserTimePlayed`+%i THEN %i ELSE `ulibUserTimePlayed`+%i END, `ulibUserLastUsedIP`='%s' WHERE `ulibUserSteamID`='%s' AND `ulibUserServer`='%s';";
	['update_user_2_nf'] = "UPDATE `ulibuser` SET `ulibUserName`='%s', `ulibUserLastVisited`=NOW(), `ulibUserTimePlayed`= CASE WHEN (%i-90)>`ulibUserTimePlayed`+%i THEN %i ELSE `ulibUserTimePlayed` END WHERE `ulibUserSteamID`='%s' AND `ulibUserServer`='%s';";
	-- Insertables Queries
	['ins_select_group_id'] = "(SELECT `ulibGroupID` FROM `ulibgroup` WHERE `ulibGroupName` = '%s' AND `ulibGroupServer` = '%s')";
	['ins_select_user_id'] = "(SELECT `ulibUserID` FROM `ulibuser` WHERE `ulibUserSteamID` = '%s' AND `ulibUserServer` = '%s')";
	-- Groups
	['select_group_list'] = "SELECT *  FROM `ulibgroup` WHERE `ulibGroupServer` = '%s' ";
	['select_group'] = "SELECT *, COUNT(*) AS Hits FROM `ulibgroup` WHERE `ulibGroupName` = '%s' AND `ulibGroupServer` = '%s' LIMIT 1;";
	['insert_group'] = "INSERT INTO `ulibgroup` (`ulibGroupName`, `ulibGroupInheritFrom`, `ulibGroupServer`, `ulibGroupDisplayName`, `ulibGroupCanTarget`) VALUES ('%s', '%s', '%s', '%s', '%s');";
	['update_group'] = "UPDATE `ulibgroup` SET `ulibGroupInheritFrom`='%s', `ulibGroupServer`='%s', `ulibGroupDisplayName`='%s', `ulibGroupCanTarget`='%s' WHERE `ulibGroupID`=%i;";
	-- Permissions
	['insert_permission'] = "INSERT INTO `ulibpermission`"..
	" (`ulibPermissionCommand`, `ulibPermissionUserID`, `ulibPermissionKind`, `ulibPermissionServer`, `ulibPermissionTag`, `ulibPermissionUserKind`)"..
	" VALUES ('%s', %s, '%s', '%s', '%s', '%s');";
	['update_permission'] = "UPDATE `ulibpermission` SET `ulibPermissionCommand`='%s', `ulibPermissionUserID`=%s, `ulibPermissionKind`='%s', `ulibPermissionServer`='%s', `ulibPermissionTag`='%s', `ulibPermissionUserKind`='%s' WHERE `ulibPermissionID`=%i;";
	['select_permission'] = "SELECT *, COUNT(*) AS Hits FROM `ulibpermission` WHERE `ulibPermissionUserID` = %s AND `ulibPermissionCommand` = '%s' AND `ulibPermissionServer` = '%s' AND `ulibPermissionUserKind` = '%s'";
	['select_permission_count'] = "SELECT `ulibPermissionKind`, COUNT(ulibPermissionID) AS Hits FROM `dehaantj_ulib_ulx`.`ulibpermission` WHERE `ulibPermissionUserID` = %s AND `ulibPermissionServer` = '%s' AND `ulibPermissionUserKind` = '%s';";
	['delete_permission'] = "DELETE FROM `ulibpermission` WHERE `ulibPermissionID` = %i AND `ulibPermissionServer` = '%s'";
	['delete_permission_user'] = "DELETE FROM `ulibpermission` WHERE `ulibPermissionUserID` = %s AND `ulibPermissionServer` = '%s' AND `ulibPermissionUserKind` = '%s' AND `ulibPermissionKind` = '%s'";
	-- Bans
	['insert_ban'] = "INSERT INTO `dehaantj_ulib_ulx`.`ulibban` (`ulibBanSteamID`, `ulibBanUserID`, `ulibBanAdminID`, `ulibBanReason`, `ulibBanMinutes`, `ulibBanIP`, `ulibBanServer`, `ulibBanTime`) VALUES ('%s', %s, %s, '%s', %i, '%s', '%s', NOW())";
	['update_ban'] = "UPDATE `dehaantj_ulib_ulx`.`ulibban` SET `ulibBanModifiedAdminID`=%s, `ulibBanModifiedTime`=NOW(), `ulibBanReason`='%s', `ulibBanMinutes`=%i WHERE `ulibBanSteamID`='%s' AND `ulibBanServer`='%s'";
	['delete_ban'] = "DELETE FROM `dehaantj_ulib_ulx`.`ulibban` WHERE `ulibBanSteamID`='%s' AND `ulibBanServer`='%s' LIMIT 1";
	--['select_bans'] = "SELECT * FROM `dehaantj_ulib_ulx`.`ulibban` WHERE `ulibBanServer`='%s'";
	--[[['select_bans'] = "SELECT users.`ulibUserName` as UserName, admins.`ulibUserName` as AdminName, admins.`ulibUserSteamID` as AdminSteamID,"..
	"modadmins.`ulibUserName` as ModifiedAdminName, modadmins.`ulibUserSteamID` as ModifiedAdminSteamID, bans.* FROM `dehaantj_ulib_ulx`.`ulibban` AS bans"..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS users ON users.`ulibUserID`=bans.`ulibBanUserID`"..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS admins ON admins.`ulibUserID`=bans.`ulibBanAdminID`"..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS modadmins ON modadmins.`ulibUserID`=bans.`ulibBanModifiedAdminID`";]]
	['select_bans'] = "SELECT users.`ulibUserName` as UserName, admins.`ulibUserName` as AdminName, admins.`ulibUserSteamID` as AdminSteamID, "..
	"modadmins.`ulibUserName` as ModifiedAdminName, modadmins.`ulibUserSteamID` as ModifiedAdminSteamID, "..
	"UNIX_TIMESTAMP(bans.`ulibBanTime`) as BanTime,  UNIX_TIMESTAMP(bans.`ulibBanModifiedTime`) as ModBanTime, bans.* "..
	"FROM `dehaantj_ulib_ulx`.`ulibban` AS bans "..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS users ON users.`ulibUserID`=bans.`ulibBanUserID` "..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS admins ON admins.`ulibUserID`=bans.`ulibBanAdminID` "..
	"LEFT OUTER JOIN `dehaantj_ulib_ulx`.`ulibuser` AS modadmins ON modadmins.`ulibUserID`=bans.`ulibBanModifiedAdminID` "..
	"WHERE bans.`ulibBanServer`='%s'";
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

include('./erayan/erayan_permissions.lua');

include('./erayan/erayan_bans.lua');

function erayan.pendingOnFailure(self, err)
	erayan.notifyerror( 'Pending SQL could\'t execute',err )
end

function erayan.pendingOnSuccess()
	erayan.pmsg( 'Processed pending query',true)
end

function erayan.databaseOnFailure(self, err)
	erayan.notifyerror( 'SQL Connect fail ',err  )
end
function erayan.databaseOnConnected(self)
	erayan.pmsg('Connected to DB',true)	
	if (#self.pending == 0) then return; end	
	erayan.pmsg( #self.pending, false,'pending queries to do.')
	local query;
	for _, info in pairs(self.pending) do
		local extra = ''
		query 			= self:query(info[1]);
		query.onFailure	= erayan.pendingOnFailure;
		query.onSuccess	= erayan.pendingOnSuccess;			
		if type(info['onData']) == 'function' then
			extra = ': with callback'			
			query.OnData = info['onData']
		end	
		query:start();
		
		print('EraYaN: ','Pending query executing'..extra..'')
	end
	self.pending = {};
	
end

-- Console Commands

function erayan.fEraYaNStatus( player, command, arguments )
local state = erayan.database:status()
local verbos = erayan.config.verbosity 
if state == 0 then
	print('EraYaN Status: ', 'Database Connection Status: Connected')
elseif state == 1 then
	print('EraYaN Status: ', 'Database Connection Status: Connecting')
elseif state == 2 then
	print('EraYaN Status: ', 'Database Connection Status: Not Connected')
elseif state == 3 then
	print('EraYaN Status: ', 'Database Connection Status: Suffered an Error')
else
	print('EraYaN Status: ', tostring(erayan.database:status()))
end
print('EraYaN Status: ', 'Verbosity: '.. verbos)
    
end 
concommand.Add( "erayan_status", erayan.fEraYaNStatus )

function erayan.fSaveGroups( player, command, arguments )
	ULib.ucl:saveGroups()    
end 
concommand.Add( "erayan_save_groups", erayan.fSaveGroups )

function erayan.fPrintGroups( player, command, arguments )
	erayan.table_print(ULib.ucl.groups,0,false)
end 
concommand.Add( "erayan_print_groups", erayan.fPrintGroups )

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
-- WARNING: This function is blocking. It is auto-called every 5 minutes.
function erayan.CheckStatus()
	if (not erayan.database or erayan.database.automaticretry) then return end
	local status = erayan.database:status()
	if (status == STATUS_WORKING or status == STATUS_READY) then
		return
	elseif (status == STATUS_ERROR) then
		erayan.notifyerror("The database object has suffered an internal error and will be recreated.")
		local pending = erayan.database.pending
		erayan.doConnect()
		erayan.database.pending = pending
	else
		erayan.notifyerror("The server has lost connection to the database. Retrying...")
		erayan.database:connect()
	end
end
timer.Create("EraYaNStatusChecker", 300, 0, erayan.CheckStatus)

erayan.doConnect()

function wakeUpWithBot()
game.ConsoleCommand( "bot\n" ) -- Execute after done loading bans
timer.Create("EraYaNRemoveBot", 10, 1, function() for k, v in pairs(player.GetBots()) do  Msg( ULib.queueFunctionCall( game.ConsoleCommand, ("kickid %i\n"):format(v:UserID()) ) ) end end)
end
hook.Add("InitPostEntity", "EraYaNWakeUpWithBot", wakeUpWithBot)
