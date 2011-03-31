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
		if kind == 'group' or kind == 'user' then
			local subQueryText = erayan.queries['select_permission_'..kind..'_id']:format(uid,erayan.config.server)	
		else
			print( 'EraYaN: ','ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['insert_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addPermissionOnFailure
		query.onSuccess = erayan.addPermissionOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Adding Permission-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Add Permission Query Pending-----------------------')
	end

end

function erayan.addPermissionOnFailure(self, err)
	notifyerror( 'SQL Add Permission Fail ', err )
end

function erayan.addPermissionOnSuccess()
	print( 'EraYaN: ', '-----------------------Added Permission----------------------- ')
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
	if ukind == 'group' or ukind == 'user' then
		local subQueryText = erayan.queries['select_permission_'..ukind..'_id']:format(uid,erayan.config.server)	
	else
		print( 'EraYaN: ','ID Kind Argument Error')
		return false
	end
		local queryText = erayan.queries['select_permission_user']:format(subQueryText,erayan.config.server, ukind)
		print( 'EraYaN: ','Query',queryText)
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
		print( 'EraYaN: ','-----------------------Checking Group Permission-----------------------')
		-- print( 'EraYaN: ',query.name,query.inherit_from,query.displayname,query.can_target)
	else
		table.insert(erayan.database.pending, {queryText; onData=erayan.checkPermissionOnData})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Check Group Permission Query Pending-----------------------')
	end

end

function erayan.checkPermissionOnFailure(self, err)
	notifyerror( 'SQL Check Permission Fail ', err )
end

function erayan.checkPermissionOnSuccess()
	print( 'EraYaN: ', '-----------------------Checked Permission----------------------- ')
end

function erayan.checkPermissionOnData(self, datarow)
	print( 'EraYaN: ','-----------------------Recieved Permission Data----------------------- ')
	if datarow['Hits']  == "0" then
		print( 'EraYaN: ','-----------------------Adding permission...----------------------- ')
		erayan.doAddPermission(self.command, self.uid, self.ukind, self.kind, self.tag)
		else
		print( 'EraYaN: ','-----------------------Updating permission...----------------------- ')
		erayan.doUpdatePermission( self.command, self.uid, self.ukind, self.kind, self.tag, datarow['ulibPermissionID'])
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
		if kind == 'group' or kind == 'user' then
			local subQueryText = erayan.queries['select_permission_'..kind..'_id']:format(uid,erayan.config.server)	
		else
			print( 'EraYaN: ','ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['update_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind, pid)
		print( 'EraYaN: ','Query',queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updatePermissionOnFailure
		query.onSuccess = erayan.updatePermissionOnSuccess
		query:start()
		print( 'EraYaN: ','-----------------------Updating Permission-----------------------')
	else
		table.insert(erayan.database.pending, {queryText})
		erayan.CheckStatus()
		print( 'EraYaN: ','-----------------------Update Permission Query Pending-----------------------')
	end
end

function erayan.updatePermissionOnFailure(self, err)
	notifyerror( 'SQL Update Permission Fail ', err )
end

function erayan.updatePermissionOnSuccess()
	print( 'EraYaN: ', '-----------------------Updated Permission----------------------- ')
end