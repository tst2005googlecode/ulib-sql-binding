-- database things in here
require("mysqloo")
local 
--[[ Config ]]--
local config = {
	hostname = "localhost"
	username = "root"
	password = ""
	database = "ulib-ulx"
	website  = "blackbox.erayan.eu"
	portnumb = 3306
	serverid = -1
	server = 'TTT'
	dogroups = false
};

local database;

-- The mysqloo ones are descriptive, but a mouthful.
STATUS_READY	= mysqloo.DATABASE_CONNECTED;
STATUS_WORKING	= mysqloo.DATABASE_CONNECTING;
STATUS_OFFLINE	= mysqloo.DATABASE_NOT_CONNECTED;
STATUS_ERROR	= mysqloo.DATABASE_INTERNAL_ERROR;


local queries = {
	-- BanChkr
	['insert_log'] = "INSERT INTO `ulxlog` (`ulxLogTimeStamp`, `ulxLogContent`) VALUES (NOW(), %s);"
};

local function blankCallback() end
local notifyerror, notifymessage
local doAddLogItem, addLogOnSuccess, addLogOnFailure
local doConnect, databaseOnFailure
-- functions
local function notifyerror(...)
	ErrorNoHalt("[", os.date(), "][SourceBans.lua] ", ...);
	print();
end
local function notifymessage(...)
	local words = table.concat({"[",os.date(),"][SourceBans.lua] ",...},"").."\n";
	ServerLog(words);
	Msg(words);
end

function doConnect()	
	database = mysqloo.connect(config.hostname, config.username, config.password, config.database, config.portnumb)
	database.onConnectionFailed = databaseOnFailure
	database.pending = {}
	database:connect()
end
function doAddLogItem(str)
	if database.status then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['insert_log']:format(str)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addLogOnFailure
		query:start()
	else
		table.insert(database.pending, {queryText, steamID, name, ply})
		CheckStatus();
	end

	end
end

function addLogOnFailure(err)
	notifyerror( 'SQL Connection fail' )
end

function databaseOnFailure(err)
	notifyerror( 'SQL Connection fail' )
end

-- Hooks
do
local function ShutDown()
		if (database) then
			database:abortAllQueries();
		end
	end

hook.Add("ShutDown", "EraYaNDBShutdown", ShutDown);
end

-- Checks the status of the database and recovers if there are errors
-- WARNING: This function is blocking. It is auto-called every 5 minutes.
function CheckStatus()
	if (not database or database.automaticretry) then return; end
	local status = database:status();
	if (status == STATUS_WORKING or status == STATUS_READY) then
		return;
	elseif (status == STATUS_ERROR) then
		notifyerror("The database object has suffered an inernal error and will be recreated.");
		local pending = database.pending;
		doConnect();
		database.pending = pending;
	else
		notifyerror("The server has lost connection to the database. Retrying...")
		database:connect();
	end
end
timer.Create("EraYaN Statur Checker", 300, 0, CheckStatus);


