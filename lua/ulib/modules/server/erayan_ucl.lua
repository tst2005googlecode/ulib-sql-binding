if not erayan then
	include('./erayan/erayan_init.lua');
end

local ucl = ULib.ucl -- Make it easier for us to refer to

-- Save what we've got with ucl.groups so far!
function ucl.saveGroups()
	for _, groupInfo in pairs( ucl.groups ) do
		table.sort( groupInfo.allow )
	end
	ucl.saveGroupsOld()
	for groupname, data in pairs(ucl.groups) do
		print('EraYaN:','-Processing Group-',groupname)
		if type(data) == "table" then
		--valid
		--[[if not data['inherit_from'] then
			local inherit_from = ''
		else
			local inherit_from = data['inherit_from']
		end]]--
			erayan.doCheckGroup(groupname, data['inherit_from'], '', data['can_target'])
			for key, command in ipairs(data['allow']) do			
				erayan.doCheckPermission(command, groupname, 'group', 'allow', data['allow'][command])
			end
			for key, command in ipairs(data['deny']) do			
				erayan.doCheckPermission(command, groupname, 'group', 'deny', data['deny'][command])
			end
		else
			print('EraYaN:','-Processing Group Fail-',groupname,data)
		end
	end
	--erayan.table_print(ucl.groups,0,false)
end

function ucl.saveUsers()
	for _, userInfo in pairs( ucl.users ) do
		table.sort( userInfo.allow )
		table.sort( userInfo.deny )
	end
	ucl.saveUsersOld()
end

function ucl.saveGroupsOld()
	file.Write( ULib.UCL_GROUPS, ULib.makeKeyValues( ucl.groups ) )
end

function ucl.saveUsersOld()
	file.Write( ULib.UCL_USERS, ULib.makeKeyValues( ucl.users ) )
end

local function reloadGroups()
	local needsBackup = false
	local err
	ucl.groups, err = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( ULib.UCL_GROUPS ), "/" ) )

	if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
		needsBackup = true
		-- Totally messed up! Clear it.
		local f = "../addons/ulib/data/" .. ULib.UCL_GROUPS
		if not file.Exists( f ) then
			print( "ULIB PANIC: groups.txt is corrupted and I can't find the default groups.txt file!!" )
		else
			local err2
			ucl.groups, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( f ), "/" ) )
			if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
				print( "ULIB PANIC: default groups.txt is corrupt!" )
				err = err2
			end
		end
		if file.Exists( ULib.UCL_REGISTERED ) then
			file.Delete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
		end
		accessStrings = {}

	else
		-- Check to make sure it passes a basic validity test
		ucl.groups[ ULib.ACCESS_ALL ].inherit_from = nil -- Ensure this is the case
		for groupName, groupInfo in pairs( ucl.groups ) do
			if type( groupName ) ~= "string" then
				needsBackup = true
				ucl.groups[ groupName ] = nil
			else

				if type( groupInfo ) ~= "table" then
					needsBackup = true
					groupInfo = {}
					ucl.groups[ groupName ] = groupInfo
				end

				if type( groupInfo.allow ) ~= "table" then
					needsBackup = true
					groupInfo.allow = {}
				end

				local inherit_from = groupInfo.inherit_from
				if inherit_from and inherit_from ~= "" and not ucl.groups[ groupInfo.inherit_from ] then
					needsBackup = true
					groupInfo.inherit_from = nil
				end

				-- Check for cycles
				local group = ucl.groupInheritsFrom( groupName )
				while group do
					if group == groupName then
						needsBackup = true
						groupInfo.inherit_from = nil
					end
					group = ucl.groupInheritsFrom( group )
				end

				if groupName ~= ULib.ACCESS_ALL and not groupInfo.inherit_from or groupInfo.inherit_from == "" then
					groupInfo.inherit_from = ULib.ACCESS_ALL -- Clean :)
				end

				-- Ensure it's lower case
				if groupName ~= groupName:lower() then
					ucl.groups[ groupName:lower() ] = groupInfo -- Copy!
					ucl.groups[ groupName ] = nil
				end

				-- Lower case'ify
				for k, v in pairs( groupInfo.allow ) do
					if type( k ) == "string" and k:lower() ~= k then
						groupInfo.allow[ k:lower() ] = v:lower()
						groupInfo.allow[ k ] = nil
					else
						groupInfo.allow[ k ] = v:lower()
					end
				end
			end
		end
	end

	if needsBackup then
		print( "Groups file was not formatted correctly. Attempting to fix and backing up original" )
		if err then
			print( "Error while reading groups file was: " .. err )
		end
		print( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_GROUPS ) )
		ucl.saveGroups()
	end
end
--reloadGroups()

local function reloadUsers()
	local needsBackup = false
	local err
	ucl.users, err = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( ULib.UCL_USERS ), "/" ) )

	-- Check to make sure it passes a basic validity test
	if not ucl.users then
		needsBackup = true
		-- Totally messed up! Clear it.
		local f = "../addons/ulib/data/" .. ULib.UCL_USERS
		if not file.Exists( f ) then
			print( "ULIB PANIC: users.txt is corrupted and I can't find the default users.txt file!!" )
		else
			local err2
			ucl.users, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( f ), "/" ) )
			if not ucl.users then
				print( "ULIB PANIC: default users.txt is corrupt!" )
				err = err2
			end
		end
		if file.Exists( ULib.UCL_REGISTERED ) then
			file.Delete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
		end
		accessStrings = {}

	else
		for id, userInfo in pairs( ucl.users ) do
			if type( id ) ~= "string" then
				needsBackup = true
				ucl.users[ id ] = nil
			else

				if type( userInfo ) ~= "table" then
					needsBackup = true
					userInfo = {}
					ucl.users[ id ] = userInfo
				end

				if type( userInfo.allow ) ~= "table" then
					needsBackup = true
					userInfo.allow = {}
				end

				if type( userInfo.deny ) ~= "table" then
					needsBackup = true
					userInfo.deny = {}
				end

				if userInfo.group and type( userInfo.group ) ~= "string" then
					needsBackup = true
					userInfo.group = nil
				end

				if userInfo.name and type( userInfo.name ) ~= "string" then
					needsBackup = true
					userInfo.name = nil
				end

				if userInfo.group == "" then userInfo.group = nil end -- Clean :)
				if userInfo.group then userInfo.group = userInfo.group:lower() end -- Ensure lower case

				-- Lower case'ify
				for k, v in pairs( userInfo.allow ) do
					if type( k ) == "string" and k:lower() ~= k then
						userInfo.allow[ k:lower() ] = v:lower()
						userInfo.allow[ k ] = nil
					else
						userInfo.allow[ k ] = v:lower()
					end
				end

				for k, v in ipairs( userInfo.deny ) do
					if type( k ) == "string" and type( v ) == "string" then -- This isn't allowed here
						table.insert( userInfo.deny, k:lower() )
						userInfo.deny[ k ] = nil
					else
						userInfo.deny[ k ] = v:lower()
					end
				end
			end
		end
	end

	if needsBackup then
		print( "Users file was not formatted correctly. Attempting to fix and backing up original" )
		if err then
			print( "Error while reading groups file was: " .. err )
		end
		print( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_USERS ) )
		ucl.saveUsers()
	end
end
--reloadUsers()