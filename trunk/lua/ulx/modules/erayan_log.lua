function ulx.logString( str, log_to_main )
	-- database part below here
	doAddLogItem(str);
	ulx.logStringOld( str, log_to_main )
	
end

function ulx.logStringOld( str, log_to_main )
	if not ulx.log_file then return end

	local date = os.date( "*t" )
	ulx.logWriteln( string.format( "[%02i:%02i:%02i] ", date.hour, date.min, date.sec ) .. str )
end