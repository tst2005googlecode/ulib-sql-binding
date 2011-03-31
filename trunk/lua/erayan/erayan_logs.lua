if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddLogItem(str)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
		local queryText = erayan.queries['insert_log']:format(os.date("%Y-%m-%d %X"),erayan.database:escape(str),erayan.config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addLogOnFailure
		query.onSuccess = erayan.addLogOnSuccess
		query.onAborted = erayan.addLogOnAborted
		query:start()
		--print('EraYaN: ',query:status(),erayan.database:status())
		print( 'EraYaN: ','-----------------------Adding Log Item-----------------------')		
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Add Log Query Pending-----------------------')
	end
end

function erayan.addLogOnFailure(self, err)
	erayan.notifyerror( 'SQL LogAdd fail ',err )
end

function erayan.addLogOnSuccess(self)
	print( 'EraYaN: ', '-----------------------Added Log Item----------------------- ')
end

function erayan.addLogOnAborted(self)
	print( 'EraYaN: ', '-----------------------Add Log Item Aborted----------------------- ', tostring(self))
end