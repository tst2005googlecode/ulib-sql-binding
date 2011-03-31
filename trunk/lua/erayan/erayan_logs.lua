if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddLogItem(str)
	if not erayan.database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = erayan.queries['insert_log']:format(erayan.database:escape(str),erayan.config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if (query) then
		query.onFailure = erayan.addLogOnFailure
		query.onSuccess = erayan.addLogOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding Log Item-----------------------')
	else
		table.insert(erayan.database.pending, {queryText, str})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Add Log Query Pending-----------------------')
	end

	end
end

function erayan.addLogOnFailure(self, err)
	erayan.notifyerror( 'SQL LogAdd fail ',err )
end

function erayan.addLogOnSuccess(query)
	print( 'EraYaN: ', '-----------------------Added Log Item----------------------- ')
end