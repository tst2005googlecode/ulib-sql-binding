if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddUser(ply, name, group)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
	local queryText = ''
	erayan.pmsg(type(ply))
	if type(ply) == 'Player' then		
		if ply:IsBot() then return end
		queryText = erayan.queries['insert_user']:format(ply:SteamID(),erayan.database:escape(ply:GetName()),'0',1,erayan.getIP(ply),erayan.getIP(ply),erayan.config.server)
	else
		subQueryText = erayan.queries['ins_select_group_id']:format(group,erayan.config.server)
		queryText = erayan.queries['insert_user']:format(ply,erayan.database:escape(name),subQueryText,0,'(unknown)','(unknown)',erayan.config.server)
	end	
	erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addUserOnFailure
		query.onSuccess = erayan.addUserOnSuccess
		query:start()
		erayan.pmsg('Adding User',true)
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Add User Query Pending',true)
	end

end

function erayan.addUserOnFailure(self, err)
	erayan.notifyerror( 'SQL Add User Fail ',err )
end

function erayan.addUserOnSuccess(query)
	erayan.pmsg('Added User',true)
end

function erayan.doCheckUser(ply, name, group)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
	local SteamID = '';	
	erayan.pmsg(type(ply))
	if type(ply) == 'Player' then
		SteamID = ply:SteamID()
		if ply:IsBot() then return end
	else
		SteamID = ply
	end	
	local queryText = erayan.queries['select_user']:format(SteamID, erayan.config.server)	
	erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkUserOnFailure
		query.onSuccess = erayan.checkUserOnSuccess
		query.onData = erayan.checkUserOnData
		query.ply = ply
		query.SteamID = SteamID	
		query.name = name
		query.group = group
		query:start()
		erayan.pmsg('Checking User',true)
	else
		table.insert(erayan.database.pending, {queryText; onData=erayan.checkGroupOnData})
		erayan.CheckStatus()
		erayan.pmsg('Check User Query Pending',true)
	end

end

function erayan.checkUserOnFailure(self, err)
	erayan.notifyerror( 'SQL LogAdd fail ',err )
end

function erayan.checkUserOnSuccess(query)
	erayan.pmsg('Checked User',true)
	--PrintTable(query:getData())
end

function erayan.checkUserOnData(self, datarow)
	erayan.pmsg('Recieved User Data',true)
	if type(ply) == 'Player' then
		SteamID = ply:SteamID()
		if self.ply:IsBot() then 
		erayan.pmsg('We dont want bots in our DB',true)
		if datarow['Hits']  == "0" then
			erayan.pmsg('Adding user...',true)
			erayan.doAddUser(self.ply)
			else
			erayan.pmsg('Updating user...',true)
			erayan.doUpdateUser(self.ply,  datarow['ulibUserID'])
		end
		return 0
	end
	else		
		if datarow['Hits']  == "0" then
			erayan.pmsg('Adding user...',true)
			erayan.doAddUser(self.SteamID, self.name, self.group)	
		else
			erayan.pmsg('Updating user...',true)
			erayan.doUpdateUser(nil,datarow['ulibUserID'], self.name, self.group)			
		end
	end	
	
	--erayan.pmsg(type(datarow['Hits']),datarow['Hits'])
	
end


function erayan.doUpdateUser(ply, id, name, group)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end	
	local queryText = ''
	if type(ply) == 'Player' then		
		if ply:IsBot() then return end
		subQueryText = erayan.queries['ins_select_group_id']:format(ply:GetUserGroup(),erayan.config.server)
		queryText = erayan.queries['update_user']:format(erayan.database:escape(ply:GetName()),subQueryText, 1, id)
	else
		subQueryText = erayan.queries['ins_select_group_id']:format(group,erayan.config.server)
		queryText = erayan.queries['update_user']:format(erayan.database:escape(name),subQueryText, 0, id)
	end	
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUserOnFailure
		query.onSuccess = erayan.updateUserOnSuccess
		query:start()
		erayan.pmsg('Updating User',true)
	else
		table.insert(erayan.database.pending, {queryText;})
		erayan.CheckStatus()
		erayan.pmsg('Update User Query Pending',true)
	end

end

function erayan.updateUserOnFailure(self, err)
	erayan.notifyerror( 'SQL Update User Fail ',err )
end

function erayan.updateUserOnSuccess()
	erayan.pmsg('Updated User',true)
end

function erayan.doUpdateUser2(ply, notfinal)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
	local frags = 0
	local deaths = 0
	local queryText = ''
	if notfinal then
		queryText = erayan.queries['update_user_2_nf']:format(erayan.database:escape(ply:GetName()), math.floor(ply:GetUTimeTotalTime()), math.floor(ply:GetUTimeSessionTime()), math.floor(ply:GetUTimeTotalTime()), ply:SteamID(), erayan.config.server)
	else		
		frags = ply:Frags()
		deaths = ply:Deaths()
		queryText = erayan.queries['update_user_2']:format(erayan.database:escape(ply:GetName()), frags, deaths, math.floor(ply:GetUTimeTotalTime()), math.floor(ply:GetUTimeSessionTime()), math.floor(ply:GetUTimeTotalTime()),math.floor(ply:GetUTimeSessionTime()), erayan.getIP(ply), ply:SteamID(), erayan.config.server)
	end
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUser2OnFailure
		query.onSuccess = erayan.updateUser2OnSuccess
		query:start()
		erayan.pmsg('Updating User (2)',true)
	else
		table.insert(erayan.database.pending, {queryText;})
		erayan.CheckStatus()
		erayan.pmsg('Update User (2) Query Pending',true)
	end

end

function erayan.updateUser2OnFailure(self, err)
	erayan.notifyerror( 'SQL Update User Fail ',err )
end

function erayan.updateUser2OnSuccess()
	erayan.pmsg('Updated User (2)',true)
end