function doAddUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if ply:IsBot() then return end
		local queryText = queries['insert_user']:format(ply:SteamID(),ply:GetName(),getIP(ply),getIP(ply),erayan_config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addUserOnFailure
		query.onSuccess = addUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Add User Query Pending-----------------------')
	end

	end
end

function addUserOnFailure(self, err)
	notifyerror( 'SQL Add User Fail ',err )
end

function addUserOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Added User----------------------- ')
end

function doCheckUser(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if ply:IsBot() then return end
		local queryText = queries['select_user']:format(ply:SteamID(),erayan_config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = checkUserOnFailure
		query.onSuccess = checkUserOnSuccess
		query.onData = checkUserOnData
		query.ply = ply
		query:start()
		print( 'EraYaN: ','-----------------------Checking User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Check User Query Pending-----------------------')
	end

	end
end

function checkUserOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function checkUserOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Checked User----------------------- ')
	--PrintTable(query:getData())
end

function checkUserOnData(self, datarow)
	print( 'EraYaN: ','-----------------------Recieved User Data----------------------- ')
	print( 'EraYaN: ','DataRow', datarow['Hits'])
	if self.ply:IsBot() then 
		print( 'EraYaN: ','-----------------------We dont want bots in our DB----------------------- ')
		return 0
	end
	print( 'EraYaN: ',type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits']  == "0" then
    print( 'EraYaN: ','-----------------------Adding user...----------------------- ')
		doAddUser(self.ply)
		else
		doUpdateUser(self.ply,  datarow['ulibUserID'])
	end
end

function doUpdateUser(ply, id)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if ply:IsBot() then return end
		local queryText = queries['update_user']:format(ply:GetName(), getIP(ply), id)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = updateUserOnFailure
		query.onSuccess = updateUserOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating User-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Update User Query Pending-----------------------')
	end

	end
end

function updateUserOnFailure(self, err)
	notifyerror( 'SQL Update User Fail ',err )
end

function updateUserOnSuccess()
	print( 'EraYaN: ', '-----------------------Updated User----------------------- ')
end

function doUpdateUser2(ply)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if ply:IsBot() then return end
		local queryText = queries['update_user_2']:format(ply:GetName(), ply:Frags(), ply:Deaths(), ply:SteamID())
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = updateUser2OnFailure
		query.onSuccess = updateUser2OnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating User (2)-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Update User (2) Query Pending-----------------------')
	end

	end
end

function updateUser2OnFailure(self, err)
	notifyerror( 'SQL Update User Fail ',err )
end

function updateUser2OnSuccess()
	print( 'EraYaN: ', '-----------------------Updated User (2)----------------------- ')
end