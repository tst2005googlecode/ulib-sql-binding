if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddGroup(name, inherit_from, displayname, can_target)
	if not erayan.database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if inherit_from == nil then
		inherit_from = ''
	end
	if can_target == nil then
		can_target = ''
	end
		local queryText = erayan.queries['insert_group']:format(name, inherit_from, erayan.config.server, erayan.database:escape(displayname), erayan.database:escape(can_target))
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if (query) then
		query.onFailure = erayan.addGroupOnFailure
		query.onSuccess = erayan.addGroupOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding Group-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Add Group Query Pending-----------------------')
	end

	end
end

function erayan.addGroupOnFailure(self, err)
	notifyerror( 'SQL Add Group Fail ', err )
end

function erayan.addGroupOnSuccess()
	print( 'EraYaN: ', '-----------------------Added Group----------------------- ')
end

function erayan.doCheckGroup(name, inherit_from, displayname, can_target)
	if not erayan.database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
	if inherit_from == nil then
		inherit_from = ''
	end
	if can_target == nil then
		can_target = ''
	end
		local queryText = erayan.queries['select_group']:format(name,erayan.config.server)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if (query) then
		query.onFailure = erayan.checkGroupOnFailure
		query.onSuccess = erayan.checkGroupOnSuccess
		query.onData = erayan.checkGroupOnData
		query.name = name
		query.inherit_from = inherit_from
		query.displayname = displayname
		query.can_target = can_target
		query:start()
		print( 'EraYaN: ','-----------------------Checking Group-----------------------')
		print( 'EraYaN: ',query.name,query.inherit_from,query.displayname,query.can_target)
	else
		table.insert(erayan.database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Check Group Query Pending-----------------------')
	end

	end
end

function erayan.checkGroupOnFailure(self, err)
	notifyerror( 'SQL Check Group Fail ', err )
end

function erayan.checkGroupOnSuccess()
	print( 'EraYaN: ', '-----------------------Checked Group----------------------- ')
end

function erayan.checkGroupOnData(self, datarow)
	print( 'EraYaN: ','-----------------------Recieved Group Data----------------------- ')
	print( 'EraYaN: ','DataRow', datarow['Hits'])
	print( 'EraYaN: ',type(datarow['Hits']),datarow['Hits'])
	if datarow['Hits']  == "0" then
		print( 'EraYaN: ','-----------------------Adding group...----------------------- ')
		erayan.doAddGroup( self.name, self.inherit_from, self.displayname, self.can_target )
		else
		print( 'EraYaN: ','-----------------------Updating group...----------------------- ')
		erayan.doUpdateGroup( datarow['ulibGroupID'], self.inherit_from, self.displayname, self.can_target )
	end
end

function erayan.doUpdateGroup(id, inherit_from, displayname, can_target)
	if not erayan.database.state == 0 then
		notifyerror( 'SQL Connection not open.' )
		return false
	else
		local queryText = erayan.queries['update_group']:format(inherit_from, erayan.config.server, erayan.database:escape(displayname), erayan.database:escape(can_target), id)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if (query) then
		query.onFailure = erayan.updateGroupOnFailure
		query.onSuccess = erayan.updateGroupOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating Group-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		CheckStatus()
		print( 'EraYaN: ','-----------------------Update Group Query Pending-----------------------')
	end

	end
end

function erayan.updateGroupOnFailure(self, err)
	notifyerror( 'SQL Update Group Fail ', err )
end

function erayan.updateGroupOnSuccess()
	print( 'EraYaN: ', '-----------------------Updated Group----------------------- ')
end
