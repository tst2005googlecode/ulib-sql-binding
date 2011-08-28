if not erayan then
	include('./erayan/erayan_init.lua');
end

function erayan.doAddPermission(command, uid, ukind, kind, tag)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
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
			subQueryText = erayan.queries['ins_select_'..ukind..'_id']:format(uid,erayan.config.server)	
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['insert_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.addPermissionOnFailure
		query.onSuccess = erayan.addPermissionOnSuccess
		query:start()
		erayan.pmsg('Adding Permission',true)
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Add Permission Query Pending',true)
	end

end

function erayan.addPermissionOnFailure(self, err)
	erayan.notifyerror( 'SQL Add Permission Fail ', err )
end

function erayan.addPermissionOnSuccess()
	erayan.pmsg( 'Added Permission',true)
end

function erayan.doCheckPermission(command, uid, ukind, kind, tag)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
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
		subQueryText = erayan.queries['ins_select_'..ukind..'_id']:format(uid,erayan.config.server)	
	else
		erayan.pmsg('ID Kind Argument Error')
		return false
	end
		local queryText = erayan.queries['select_permission']:format(subQueryText, command, erayan.config.server, ukind)
		erayan.dmsg('Query',false,queryText)
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
		table.insert(erayan.database.pending, {queryText; onData=erayan.checkPermissionOnData;})
		erayan.CheckStatus()
		erayan.pmsg('Check Permission Query Pending',true)
	end

end

function erayan.checkPermissionOnFailure(self, err)
	erayan.notifyerror( 'SQL Check Permission Fail ', err )
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
		
		if not datarow['ulibPermissionTag'] == self.tag or not datarow['ulibPermissionKind'] == self.kind then
			erayan.pmsg('Updating permission...',true)
			erayan.doUpdatePermission( self.command, self.uid, self.ukind, self.kind, self.tag, datarow['ulibPermissionID'])
		end
	end
end

function erayan.doUpdatePermission(command, uid, ukind, kind, tag, pid)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
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
			subQueryText = erayan.queries['ins_select_'..ukind..'_id']:format(uid,erayan.config.server)					
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['update_permission']:format(command, subQueryText, kind, erayan.config.server, tag, ukind, pid)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.updatePermissionOnFailure
		query.onSuccess = erayan.updatePermissionOnSuccess
		query:start()
		erayan.pmsg('Updating Permission',true)
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Update Permission Query Pending',true)
	end
end

function erayan.updatePermissionOnFailure(self, err)
	erayan.notifyerror( 'SQL Update Permission Fail ', err )
end

function erayan.updatePermissionOnSuccess()
	erayan.pmsg( 'Updated Permission',true)
end

function erayan.doRemoveUserPermissions(uid, ukind, data, pkind)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
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
			subQueryText = erayan.queries['ins_select_'..ukind..'_id']:format(uid,erayan.config.server)	
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['delete_permission_user']:format(subQueryText, erayan.config.server, ukind, pkind)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.removeUserPermissionsOnFailure
		query.onSuccess = erayan.removeUserPermissionsOnSuccess
		query.uid = uid
		query.ukind = ukind
		query.data = data
		query.pkind = pkind
		query:start()
		erayan.pmsg('Removing User Permissions',true)
	else
		table.insert(erayan.database.pending, {queryText; query})
		erayan.CheckStatus()
		erayan.pmsg('Remove User Permissions Query Pending',true)
	end
end

function erayan.removeUserPermissionsOnFailure(self, err)
	erayan.notifyerror( 'SQL Remove User Permissions Fail ', err )
end

function erayan.removeUserPermissionsOnSuccess(self)
	erayan.pmsg( 'Removed User/Group Permissions ('..self.pkind..')',true)
	erayan.saveGroupsTwo(self.uid, self.data, self.pkind)
end

function erayan.doCheckUserPermissions(uid, ukind, data)
	if not erayan.database:status() == 0 then
		erayan.notifyerror( 'SQL Connection not open.' )
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
			subQueryText = erayan.queries['ins_select_'..ukind..'_id']:format(uid,erayan.config.server)				
		else
			erayan.pmsg('ID Kind Argument Error')
			return false
		end
		local queryText = erayan.queries['select_permission_count']:format(subQueryText, erayan.config.server, ukind)
		erayan.dmsg('Query',false,queryText)
	local query = erayan.database:query(queryText)
	if query and erayan.database:status() == 0 then
		query.onFailure = erayan.checkUserPermissionsOnFailure
		query.onSuccess = erayan.checkUserPermissionsOnSuccess
		query.onData	= erayan.checkUserPermissionsOnData
		query.uid = uid
		query.ukind = ukind
		query.data = data
		query:start()
		erayan.pmsg('Checking User/Group Permissions',true)
	else
		table.insert(erayan.database.pending, {queryText; onData=erayan.checkUserPermissionsOnData})
		erayan.CheckStatus()
		erayan.pmsg('Check User/Group Permissions Query Pending',true)
	end
end

function erayan.checkUserPermissionsOnFailure(self, err)
	erayan.notifyerror( 'SQL Check User/Group Permissions Fail ', err )
end

function erayan.checkUserPermissionsOnSuccess()
	erayan.pmsg( 'Checked User/Group Permissions',true)
end

function erayan.checkUserPermissionsOnData(self, datarow)
	erayan.pmsg('Recieved User/Group Permission Data',true)
	if not datarow['ulibPermissionKind'] then
		if self.ukind == 'group' then
			erayan.saveGroupsTwo(self.uid ,self.data, 'allow')
			erayan.saveGroupsTwo(self.uid ,self.data, 'deny') 
		elseif self.ukind == 'user' then
			erayan.saveUsersTwo(self.uid ,self.data, 'allow')
			erayan.saveUsersTwo(self.uid ,self.data, 'deny') 
		end
	end
		erayan.table_print(self.data)
		erayan.table_print(datarow)
		local localhits = 0
		if not datarow['ulibPermissionKind'] then
			localhits = 0
			else
			localhits = #self.data[datarow['ulibPermissionKind']]
		end
		print(datarow['ulibPermissionKind'])
		print(type(datarow['Hits']),localhits)
		if tonumber(datarow['Hits']) > localhits then
				erayan.pmsg('Removing User/Group Permissions...',true)
				erayan.doRemoveUserPermissions(self.uid, self.ukind, self.data, datarow['ulibPermissionKind'])
		else
			if self.ukind == 'group' then
				erayan.saveGroupsTwo(self.uid ,self.data, datarow['ulibPermissionKind'])
			elseif self.ukind == 'user' then
				erayan.saveUsersTwo(self.uid ,self.data, datarow['ulibPermissionKind'])
			end			
		end
end