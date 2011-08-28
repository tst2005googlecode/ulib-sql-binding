if not erayan then
	include('./erayan/erayan_init.lua');
end

-- slap/kick hook function
function commandHook(ply, commandName, translated_args)
    -- slap action
	if commandName == 'ulx slap' then
	print( 'EraYaN: ', 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=slapper
		2=user targets
		3=dmg
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Slap' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Slap' ,key, value)
		end
	end
	end
	-- kick action
	if commandName == 'ulx kick' then
	print( 'EraYaN: ', 'Kicked someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=kicker
		2=user being kicked
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Kick' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Kick' ,key, value)
		end
	end

	end
	if commandName == 'ulx ban' then
	print( 'EraYaN: ', 'Banned someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=banned
		2=user being banned
		3=reason
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Ban' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Ban' ,key, value)
		end
	end

	end
end
hook.Add("ULibPostTranslatedCommand", "EraYaNCommandHook", commandHook)


-- player join (add to mysql database)
function playerJoinDB(ply)
	erayan.dmsg( ('Player %s Joined'):format(ply:Name()), true)
	erayan.doCheckUser(ply)
end
hook.Add("UCLAuthed", "EraYaNPlayerAuthedHook", playerJoinDB)

-- player database update, ran every 15 minutes
function updateAllPlayers()
erayan.imsg()
	for k, v in pairs(player.GetAll()) do
		erayan.doUpdateUser2(v,true)
	end

end
timer.Create("EraYaNPlayerUpdater", 15*60, 0, updateAllPlayers)

--[[
	Function: ban

	Bans a user.

	Parameters:

		ply - The player to ban.
		time - *(Optional)* The time in minutes to ban the person for, leave nil or 0 for permaban.
		reason - *(Optional)* The reason for banning
		admin - *(Optional)* Admin player enacting ban

	Revisions:

		v2.10 - Added support for custom ban list
]]
--[[function ULib.banOld( ply, time, reason, admin )
	if not time or type( time ) ~= "number" then
		time = 0
	end

	ULib.addBan( ply:SteamID(), time, reason, ply:Name(), admin )

	-- Load our currently banned users so we don't overwrite them
	if file.Exists( "../cfg/banned_user.cfg" ) then
		ULib.execFile( "../cfg/banned_user.cfg" )
	end
end]]


--[[
	Function: kickban

	Kicks and bans a user.

	Parameters:

		ply - The player to ban.
		time - *(Optional)* The time in minutes to ban the person for, leave nil or 0 for permaban.
		reason - *(Optional)* The reason for banning
		admin - *(Optional)* Admin player enacting ban

	Revisions:

		v2.10 - Added support for custom ban list
]]
--[[function ULib.kickban( ply, time, reason, admin )
	if not time or type( time ) ~= "number" then
		time = 0
	end

	ULib.addBan( ply:SteamID(), time, reason, ply:Name(), admin )

	-- Load our currently banned users so we don't overwrite them
	if file.Exists( "../cfg/banned_user.cfg" ) then
		ULib.execFile( "../cfg/banned_user.cfg" )
	end
end]]

--[[
	Function: addBan

	Helper function to store additional data about bans.

	Parameters:

		steamid - Banned player's steamid
		time - Length of ban
		reason - *(Optional)* Reason for banning
		name - *(Optional)* Name of player banned
		admin - *(Optional)* Admin player enacting the ban

	Revisions:

		2.10 - Initial
		2.40 - If the steamid is connected, kicks them with the reason given
]]
function ULib.addBan( steamid, time, reason, name, admin )
	local players = player.GetAll()
	local bannedfromip = "(unknown)";
	for i=1, #players do
		if players[ i ]:SteamID() == steamid then
			local ply = players[ i ]
			bannedfromip = erayan.getIP(ply)
			ULib.kick( players[ i ], reason )			
		end
	end

	game.ConsoleCommand( string.format( "banid %f %s kick\n", time, steamid ) )
	game.ConsoleCommand( "writeid\n" )
	local adminsteamid
	local admin_name
	local ban_updated = false
	if admin then
		admin_name = "(Console)"
		adminsteamid = "(Console)"
		if admin:IsValid() then
			admin_name = string.format( "%s(%s)", admin:Name(), admin:SteamID() )
			adminsteamid = admin:SteamID();
		end
	end

	local t = {}
	
	if ULib.bans[ steamid ] then
		t = ULib.bans[ steamid ]
		t.modified_admin = admin_name
		t.modified_time = os.time()
		ban_updated = true
	else
		t.admin = admin_name
	end
	t.time = t.time or os.time()
	if time > 0 then
		t.unban = ( ( time * 60 ) + os.time() )
	else
		t.unban = 0
	end
	if reason then
		t.reason = reason
	end
	if name then
		t.name = name
	end
	ULib.bans[ steamid ] = t
	file.Write( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
	if ban_updated then
		erayan.doUpdateBan(t, steamid, adminsteamid)
	else	
		erayan.doAddBan(t, steamid, adminsteamid, bannedfromip)
	end	
end

--[[
	Function: unbanOld

	Unbans the given steamid.

	Parameters:

		steamid - The steamid to unban.

	Revisions:

		v2.10 - Initial
]]
function ULib.unban( steamid )

	--Default banlist
	if file.Exists( "../cfg/banned_user.cfg" ) then
		ULib.execFile( "../cfg/banned_user.cfg" )
	end
	ULib.queueFunctionCall( game.ConsoleCommand, "removeid " .. steamid .. ";writeid\n" ) -- Execute after done loading bans

	--ULib banlist
	ULib.bans[ steamid ] = nil
	file.Write( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
	erayan.doUnBan(steamid)
end

--[[
	Function: refreshBansOld

	Refreshes the ULib bans.
]]
function ULib.refreshBansOld()
	local err
	if not file.Exists( ULib.BANS_FILE ) then
		ULib.bans = {}
	else
		ULib.bans, err = ULib.parseKeyValues( file.Read( ULib.BANS_FILE ) )
	end

	if err then
		Msg( "Bans file was not formatted correctly. Attempting to fix and backing up original\n" )
		if err then
			Msg( "Error while reading bans file was: " .. err .. "\n" )
		end
		Msg( "Original file was backed up to " .. ULib.backupFile( ULib.BANS_FILE ) .. "\n" )
		ULib.bans = {}
	end

	local default_bans = ""
	if file.Exists( "../cfg/banned_user.cfg" ) then
		ULib.execFile( "../cfg/banned_user.cfg" )
		ULib.queueFunctionCall( game.ConsoleCommand, "writeid\n" )
		default_bans = file.Read( "../cfg/banned_user.cfg" )
	end

	--default_bans = ULib.makePatternSafe( default_bans )
	default_bans = string.gsub( default_bans, "banid %d+ ", "" )
	default_bans = string.Explode( "\n", default_bans:gsub( "\r", "" ) )
	local ban_set = {}
	for _, v in pairs( default_bans ) do
		if v ~= "" then
			ban_set[ v ] = true
			if not ULib.bans[ v ] then
				ULib.bans[ v ] = { unban = 0 }
			end
		end
	end

	for k, v in pairs( ULib.bans ) do
		if type( v ) == "table" and type( k ) == "string" then
			local time = ( v.unban - os.time() ) / 60
			if time > 0 then
				game.ConsoleCommand( string.format( "banid %f %s\n", time, k ) )
			elseif math.floor( v.unban ) == 0 then -- We floor it because GM10 has floating point errors that might make it be 0.1e-20 or something dumb.
				if not ban_set[ k ] then
					ULib.bans[ k ] = nil
				end
			else
				ULib.bans[ k ] = nil
			end
		else
			Msg( "Warning: Bad ban data is being ignored, key = " .. tostring( k ) .. "\n" )
			ULib.bans[ k ] = nil
		end
	end

	-- We're queueing this because it will split the load out for VERY large ban files
	ULib.queueFunctionCall( function() file.Write( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) ) end )
end
PCallError( ULib.refreshBansOld )

function ULib.refreshBans()
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()	
		--ULib.refreshBansOld()
	end
		
		erayan.doGetBans()
		ULib.queueFunctionCall( function() file.Write( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) ) end )
		
end
ULib.refreshBans()
concommand.Add( "erayan_refreshbans", erayan.refreshBans )