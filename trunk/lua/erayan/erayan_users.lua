if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddUser(ply)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['insert_user']:format(ply:SteamID(),erayan.database:escape(ply:GetName()),erayan.getIP(ply),erayan.getIP(ply),erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addUserOnFailure
		query.onSuccess = erayan.addUserOnSuccess
		query:start()
		erayan.pmsg('Adding User',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
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

function erayan.doCheckUser(ply)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['select_user']:format(ply:SteamID(), erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkUserOnFailure
		query.onSuccess = erayan.checkUserOnSuccess
		query.onData = erayan.checkUserOnData
		query.ply = ply
		query:start()
		erayan.pmsg('Checking User',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query; onData=erayan.checkGroupOnData})
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
	if self.ply:IsBot() then 
		erayan.pmsg('We dont want bots in our DB',true)
		return 0
	end
	--erayan.pmsg(type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits']  == "0" then
		erayan.pmsg('Adding user...',true)
		erayan.doAddUser(self.ply)
		else
		erayan.pmsg('Updating user...',true)
		erayan.doUpdateUser(self.ply,  datarow['ulibUserID'])
	end
end

function erayan.doUpdateUser(ply, id)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['update_user']:format(erayan.database:escape(ply:GetName()), erayan.getIP(ply), id)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUserOnFailure
		query.onSuccess = erayan.updateUserOnSuccess
		query:start()
		erayan.pmsg('Updating User',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
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

function erayan.doUpdateUser2(ply)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['update_user_2']:format(erayan.database:escape(ply:GetName()), ply:Frags(), ply:Deaths(), math.floor((ply:GetUTime() + CurTime() - ply:GetUTimeStart()), ply:SteamID(), erayan.config.server))
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUser2OnFailure
		query.onSuccess = erayan.updateUser2OnSuccess
		query:start()
		erayan.pmsg('Updating User (2)',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
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