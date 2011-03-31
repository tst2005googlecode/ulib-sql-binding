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
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addUserOnFailure
		query.onSuccess = erayan.addUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding User-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Add User Query Pending-----------------------')
	end

end

function erayan.addUserOnFailure(self, err)
	erayan.notifyerror( 'SQL Add User Fail ',err )
end

function erayan.addUserOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Added User----------------------- ')
end

function erayan.doCheckUser(ply)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['select_user']:format(ply:SteamID(),erayan.config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkUserOnFailure
		query.onSuccess = erayan.checkUserOnSuccess
		query.onData = erayan.checkUserOnData
		query.ply = ply
		query:start()
		print( 'EraYaN: ','-----------------------Checking User-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Check User Query Pending-----------------------')
	end

end

function erayan.checkUserOnFailure(self, err)
	erayan.notifyerror( 'SQL LogAdd fail ',err )
end

function erayan.checkUserOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Checked User----------------------- ')
	--PrintTable(query:getData())
end

function erayan.checkUserOnData(self, datarow)
	print( 'EraYaN: ','-----------------------Recieved User Data----------------------- ')
	print( 'EraYaN: ','DataRow', datarow['Hits'])
	if self.ply:IsBot() then 
		print( 'EraYaN: ','-----------------------We dont want bots in our DB----------------------- ')
		return 0
	end
	print( 'EraYaN: ',type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits']  == "0" then
		print( 'EraYaN: ','-----------------------Adding user...----------------------- ')
		erayan.doAddUser(self.ply)
		else
		print( 'EraYaN: ','-----------------------Updating user...----------------------- ')
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
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUserOnFailure
		query.onSuccess = erayan.updateUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating User-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Update User Query Pending-----------------------')
	end

end

function erayan.updateUserOnFailure(self, err)
	erayan.notifyerror( 'SQL Update User Fail ',err )
end

function erayan.updateUserOnSuccess()
	print( 'EraYaN: ', '-----------------------Updated User----------------------- ')
end

function erayan.doUpdateUser2(ply)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if ply:IsBot() then return end
		local queryText = erayan.queries['update_user_2']:format(erayan.database:escape(ply:GetName()), ply:Frags(), ply:Deaths(), ply:SteamID())
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateUser2OnFailure
		query.onSuccess = erayan.updateUser2OnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating User (2)-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Update User (2) Query Pending-----------------------')
	end

end

function erayan.updateUser2OnFailure(self, err)
	erayan.notifyerror( 'SQL Update User Fail ',err )
end

function erayan.updateUser2OnSuccess()
	print( 'EraYaN: ', '-----------------------Updated User (2)----------------------- ')
end