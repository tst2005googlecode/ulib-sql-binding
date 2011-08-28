if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddLogItem(str)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
		local queryText = erayan.queries['insert_log']:format(os.date("%Y-%m-%d %X"),erayan.database:escape(str),erayan.config.server)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addLogOnFailure
		query.onSuccess = erayan.addLogOnSuccess
		query.onAborted = erayan.addLogOnAborted
		query:start()
		--print('EraYaN: ',query:status(),erayan.database:status())
		erayan.pmsg('Adding Log Item',true)		
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Add Log Query Pending',true)
	end
end

function erayan.addLogOnFailure(self, err)
	erayan.notifyerror( 'SQL LogAdd fail ',err )
end

function erayan.addLogOnSuccess(self)
	erayan.pmsg( 'Added Log Item',true)
end

function erayan.addLogOnAborted(self)
	erayan.pmsg( 'Add Log Item Aborted',true, tostring(self))
end