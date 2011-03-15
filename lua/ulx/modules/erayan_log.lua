local logFile = ulx.convar( "logFile", "1", "", ULib.ACCESS_SUPERADMIN )
local logDir  = ulx.convar( "logDir", "ulx_logs", "", ULib.ACCESS_SUPERADMIN )
local next_log
local curDay
function ulx.logString( str, log_to_main )
	-- database part below here
	doAddLogItem(str);
	ulx.logStringOld( str, log_to_main )
	
end

local function next_log()
	if logFile:GetBool() then
		local new_log = os.date( logDir:GetString() .. "/" .. "%m-%d-%y" .. ".txt" )
		if new_log == ulx.log_file then -- Make sure the date has changed.
			return
		end
		local old_log = ulx.log_file
		ulx.logWriteln( "<Logging continued in \"" .. new_log .. "\">" )
		ulx.log_file = new_log
		file.Write( ulx.log_file, "" )
		ulx.logWriteln( "<Logging continued from \"" .. old_log .. "\">" )
	end
	curDay = os.date( "%d" )
end

function ulx.logStringOld( str, log_to_main )
	if not ulx.log_file then return end

	local date = os.date( "*t" )
	if curDay ~= date.day then
		next_log()
	end

	if log_to_main then
		ServerLog( "[ULX] " .. str .. "\n" )
	end
	ulx.logWriteln( string.format( "[%02i:%02i:%02i] ", date.hour, date.min, date.sec ) .. str )
end

