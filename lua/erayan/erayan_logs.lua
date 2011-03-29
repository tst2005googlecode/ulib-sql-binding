function doAddLogItem(str)
	if not database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = queries['insert_log']:format(str,erayan_config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = database:query(queryText)
	if (query) then
		query.onFailure = addLogOnFailure
		query.onSuccess = addLogOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding Log Item-----------------------')
	else
		table.insert(database.pending, {queryText, str})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Add Log Query Pending-----------------------')
	end

	end
end

function addLogOnFailure(self, err)
	notifyerror( 'SQL LogAdd fail ',err )
end

function addLogOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Added Log Item----------------------- ')
end