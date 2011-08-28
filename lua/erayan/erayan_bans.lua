if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddBan(t, steamid, adminsteamid, bannedfromip)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	
	subQueryTextUser = erayan.queries['ins_select_user_id']:format(steamid,erayan.config.server)
	subQueryTextAdmin = erayan.queries['ins_select_user_id']:format(adminsteamid,erayan.config.server)
	local reason
	if t.reason then
		reason = t.reason
	else
		reason = ""
	end	--`ulibBanSteamID`, `ulibBanUserID`, `ulibBanAdminID`, `ulibBanReason`, `ulibBanMinutes`, `ulibBanIP`, `ulibBanServer`
		local queryText = erayan.queries['insert_ban']:format(steamid, subQueryTextUser, subQueryTextAdmin, reason, math.floor((t.unban-os.time())/60), bannedfromip, erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addBanOnFailure
		query.onSuccess = erayan.addBanOnSuccess		
		query:start()
		--print('EraYaN: ',query:status(),erayan.database:status())
		erayan.pmsg('Adding Ban',true)		
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Add Ban Query Pending',true)
	end
end

function erayan.addBanOnFailure( self, err )
	erayan.notifyerror( 'SQL BanAdd fail ', err )
end

function erayan.addBanOnSuccess( self )
	erayan.pmsg( 'Added Ban',true)
end

function erayan.doUpdateBan(t, steamid, adminsteamid)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
	subQueryTextAdmin = erayan.queries['ins_select_user_id']:format(adminsteamid,erayan.config.server)
	local reason
	if t.reason then
		reason = t.reason
	else
		reason = ""
	end	
		--`ulibBanModifiedAdminID`=%i, `ulibBanModifiedTime`=NOW(), `ulibBanReason`='%s', `ulibBanMinutes`=%i WHERE `ulibBanSteamID`='%s' AND `ulibBanServer`='%s'"
		local queryText = erayan.queries['update_ban']:format(subQueryTextAdmin, reason, math.floor((t.unban-os.time())/60), steamid, erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateBanOnFailure
		query.onSuccess = erayan.updateBanOnSuccess		
		query:start()
		--print('EraYaN: ',query:status(),erayan.database:status())
		erayan.pmsg('Updating Ban',true)		
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Update Ban Query Pending',true)
	end
end

function erayan.addBanOnFailure( self, err )
	erayan.notifyerror( 'SQL Ban Update fail ', err )
end

function erayan.addBanOnSuccess( self )
	erayan.pmsg( 'Updated Ban',true)
end

function erayan.doUnBan(steamid)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
		--`ulibBanSteamID`='%s' AND `ulibBanServer`='%s'"
		local queryText = erayan.queries['delete_ban']:format(steamid, erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.unBanOnFailure
		query.onSuccess = erayan.unBanOnSuccess		
		query:start()
		--print('EraYaN: ',query:status(),erayan.database:status())
		erayan.pmsg('Deleting Ban',true)		
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Delete Ban Query Pending',true)
	end
end

function erayan.unBanOnFailure( self, err )
	erayan.notifyerror( 'SQL Ban Delete fail ', err )
end

function erayan.unBanOnSuccess( self )
	erayan.pmsg( 'Deleted Ban',true)
end

function erayan.doGetBans()
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
	local queryText = erayan.queries['select_bans']:format(erayan.config.server)
	erayan.dmsg('Query',false,queryText)
	local default_bans = ""
	if file.Exists( "../cfg/banned_user.cfg" ) then
		ULib.execFile( "../cfg/banned_user.cfg" )
		ULib.queueFunctionCall( game.ConsoleCommand, "writeid\n" )
		default_bans = file.Read( "../cfg/banned_user.cfg" )
	end

	--default_bans = ULib.makePatternSafe( default_bans )
	default_bans = string.gsub( default_bans, "banid %d+ ", "" )
	default_bans = string.Explode( "\n", default_bans:gsub( "\r", "" ) )
	--[[local ban_set = {}
	for _, v in pairs( default_bans ) do
		if v ~= "" then
			ban_set[ v ] = true
			if not ULib.bans[ v ] then
				ULib.bans[ v ] = { unban = 0 }
			end
		end
	end	]]
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.getBansOnFailure
		query.onSuccess = erayan.getBansOnSuccess
		query.onData = erayan.getBansOnData
		//query.ban_set = ban_set
		query:start()
		ULib.bans = {}
		erayan.pmsg('Getting Bans',true)
	else
		table.insert(erayan.database.pending, {queryText; onData=erayan.getBansOnData;})
		erayan.CheckStatus()
		erayan.pmsg('Get Bans Query Pending',true)
	end
	
end

function erayan.getBansOnFailure(self, err)
	erayan.notifyerror( 'SQL GetBans fail ',err )
end

function erayan.getBansOnSuccess(query)
	erayan.pmsg('Got Bans',true)
	--PrintTable(query:getData())
end

function erayan.getBansOnData(self, datarow)
	erayan.pmsg('Recieved Ban Data',true)	
	steamid = datarow['ulibBanSteamID']
	local t = {}
	if datarow['ModiefiedAdminName'] then
		t.modified_admin = string.format( "%s(%s)", datarow['ModiefiedAdminName'], datarow['ModiefiedAdminSteamID'] )		
	end
	if datarow['AdminName'] then
		t.admin = string.format( "%s(%s)", datarow['AdminName'], datarow['AdminSteamID'] )		
	end
	if datarow['UserName'] then
		t.name = datarow['UserName']
	end
	if datarow['ulibBanReason'] then
		t.reason = datarow['ulibBanReason']
	end
	if datarow['BanTime'] then
		t.time = datarow['BanTime']
	end
	if datarow['ulibBanMinutes'] or datarow['ulibBanMinutes'] == 0 then
		if datarow['ulibBanMinutes'] == 0 then
			t.unban = 0
		else
			t.unban = datarow['BanTime']+datarow['ulibBanMinutes']*60
		end		
	end
	ULib.bans[ steamid ] = t
	local time = (t.unban - os.time())/60
	if time > 0 then
		game.ConsoleCommand( string.format( "banid %f %s\n", time, steamid) )	
		erayan.dmsg(('Banned user %s for %i more minutes'):format(steamid, time),false)
	elseif math.floor( datarow['ulibBanMinutes'] ) == 0 then -- We floor it because GM10 has floating point errors that might make it be 0.1e-20 or something dumb.
		--[[if not self.ban_set[ steamid ] then
			ULib.bans[ steamid ] = nil
		end	]]	
		erayan.dmsg(('Banned user %s permanently'):format(steamid),false)
	else
		ULib.bans[ steamid ] = nil
		erayan.dmsg(('Removed user ban for %s'):format(steamid),false)
		erayan.doUnBan(steamid)
	end	
end