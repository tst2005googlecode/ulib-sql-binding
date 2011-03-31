if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddPermission(command, uid, ukind, kind, tag)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if tag == nil then
		tag = ''
	end
	if kind == nil then
		kind = 'allow'
	end
		local subQueryText = ''
		if ukind == 'group' or ukind == 'user' then
			subQueryText = erayan.queries['select_permission_'..ukind..'_id']:format(uid,erayan.config.server)	
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['insert_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind)
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addPermissionOnFailure
		query.onSuccess = erayan.addPermissionOnSuccess
		query:start()
		erayan.pmsg('Adding Permission',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
		erayan.CheckStatus()
		erayan.pmsg('Add Permission Query Pending',true)
	end

end

function erayan.addPermissionOnFailure(self, err)
	notifyerror( 'SQL Add Permission Fail ', err )
end

function erayan.addPermissionOnSuccess()
	erayan.pmsg( 'Added Permission',true)
end

function erayan.doCheckPermission(command, uid, ukind, kind, tag)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if tag == nil then
		tag = ''
	end
	if kind == nil then
		kind = 'allow'
	end
	local subQueryText = ''
	if ukind == 'group' or ukind == 'user' then
		subQueryText = erayan.queries['select_permission_'..ukind..'_id']:format(uid,erayan.config.server)	
	else
		erayan.pmsg('ID Kind Argument Error')
		return false
	end
		local queryText = erayan.queries['select_permission']:format(subQueryText, command, erayan.config.server, ukind)
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkPermissionOnFailure
		query.onSuccess = erayan.checkPermissionOnSuccess
		query.onData = erayan.checkPermissionOnData
		query.command = command
		query.uid = uid
		query.ukind = ukind
		query.kind = kind
		query.tag = tag
		query:start()
		erayan.pmsg('Checking Group Permission',true)
		-- erayan.pmsg(query.name,query.inherit_from,query.displayname,query.can_target)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query; onData=erayan.checkPermissionOnData;})
		erayan.CheckStatus()
		erayan.pmsg('Check Permission Query Pending',true)
	end

end

function erayan.checkPermissionOnFailure(self, err)
	notifyerror( 'SQL Check Permission Fail ', err )
end

function erayan.checkPermissionOnSuccess()
	erayan.pmsg( 'Checked Permission',true)
end

function erayan.checkPermissionOnData(self, datarow)
	erayan.pmsg('Recieved Permission Data',true)
	if datarow['Hits']  == "0" then
		erayan.pmsg('Adding permission...',true)
		erayan.doAddPermission(self.command, self.uid, self.ukind, self.kind, self.tag)
		else
		erayan.pmsg('Updating permission...',true)
		if not datarow['ulibPermissionTag'] == self.tag or not datarow['ulibPermissionKind'] == self.kind then
			erayan.doUpdatePermission( self.command, self.uid, self.ukind, self.kind, self.tag, datarow['ulibPermissionID'])
		end
	end
end

function erayan.doUpdatePermission(command, uid, ukind, kind, tag, pid)
	if not erayan.database:status() == 0 then
		notifyerror( 'SQL Connection not open.' )
		erayan.CheckStatus()		
	end
	if tag == nil then
		tag = ''
	end
	if kind == nil then
		kind = 'allow'
	end
		local subQueryText = ''
		if ukind == 'group' or ukind == 'user' then
			subQueryText = erayan.queries['select_permission_'..ukind..'_id']:format(uid,erayan.config.server)	
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['update_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind, pid)
		erayan.pmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updatePermissionOnFailure
		query.onSuccess = erayan.updatePermissionOnSuccess
		query:start()
		erayan.pmsg('Updating Permission',true)
	else
		table.insert(erayan.database.pending, {queryText; queryObj=query})
		erayan.CheckStatus()
		erayan.pmsg('Update Permission Query Pending',true)
	end
end

function erayan.updatePermissionOnFailure(self, err)
	notifyerror( 'SQL Update Permission Fail ', err )
end

function erayan.updatePermissionOnSuccess()
	erayan.pmsg( 'Updated Permission',true)
end