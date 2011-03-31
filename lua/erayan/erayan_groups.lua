if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddGroup(name, inherit_from, displayname, can_target)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if not inherit_from then
		inherit_from = ''
	end
	if not displayname then
		displayname = ''
	end
	if not can_target then
		can_target = ''
	end
		local queryText = erayan.queries['insert_group']:format(name, inherit_from, erayan.config.server, erayan.database:escape(displayname), erayan.database:escape(can_target))
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addGroupOnFailure
		query.onSuccess = erayan.addGroupOnSuccess
		query:start()
		erayan.pmsg('Adding Group',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
		erayan.CheckStatus()
		erayan.pmsg('Add Group Query Pending',true)
	end

end

function erayan.addGroupOnFailure(self, err)
	notifyerror( 'SQL Add Group Fail ', err )
end

function erayan.addGroupOnSuccess()
	erayan.pmsg( 'Added Group',true)
end

function erayan.doCheckGroup(name, inherit_from, displayname, can_target)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if inherit_from == nil then
		inherit_from = ''
	end
	if can_target == nil then
		can_target = ''
	end
		local queryText = erayan.queries['select_group']:format(name,erayan.config.server)
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkGroupOnFailure
		query.onSuccess = erayan.checkGroupOnSuccess
		query.onData = erayan.checkGroupOnData
		query.name = name
		query.inherit_from = inherit_from
		query.displayname = displayname
		query.can_target = can_target
		query:start()
		erayan.pmsg('Checking Group',true)
		--erayan.pmsg(query.name,query.inherit_from,query.displayname,query.can_target)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query; onData=erayan.checkGroupOnData})
		erayan.CheckStatus()
		erayan.pmsg('Check Group Query Pending',true)
	end

end



function erayan.checkGroupOnFailure(self, err)
	notifyerror( 'SQL Check Group Fail ', err )
end

function erayan.checkGroupOnSuccess()
	erayan.pmsg( 'Checked Group',true)
end

function erayan.checkGroupOnData(self, datarow)
	erayan.pmsg('Recieved Group Data',true)
	if datarow['Hits']  == "0" then
		erayan.pmsg('Adding group...',true)
		erayan.doAddGroup( self.name, self.inherit_from, self.displayname, self.can_target )
		else
		erayan.pmsg('Updating group...',true)
		erayan.doUpdateGroup( datarow['ulibGroupID'], self.inherit_from, self.displayname, self.can_target )
	end
end

function erayan.doUpdateGroup(id, inherit_from, displayname, can_target)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
		local queryText = erayan.queries['update_group']:format(inherit_from, erayan.config.server, erayan.database:escape(displayname), erayan.database:escape(can_target), id)
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updateGroupOnFailure
		query.onSuccess = erayan.updateGroupOnSuccess
		query:start()
		erayan.pmsg('Updating Group',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
		erayan.CheckStatus()
		erayan.pmsg('Update Group Query Pending',true)
	end
end

function erayan.updateGroupOnFailure(self, err)
	notifyerror( 'SQL Update Group Fail ', err )
end

function erayan.updateGroupOnSuccess()
	erayan.pmsg( 'Updated Group',true)
end
