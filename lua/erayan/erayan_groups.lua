function doAddGroup(ply)
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
		print( 'EraYaN: ','-----------------------Adding Group-----------------------')
	else
		table.insert(database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Add Group Query Pending-----------------------')
	end

	end
end

function addGroupOnFailure(self, err)
	notifyerror( 'SQL Add Group Fail ', err )
end

function addGroupOnSuccess()
	print( 'EraYaN: ', '-----------------------Added Group----------------------- ')
end
