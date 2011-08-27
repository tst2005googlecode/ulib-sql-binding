if not erayan then
	include('./erayan/erayan_init.lua');
end

-- slap/kick hook function
function commandHook(ply, commandName, translated_args)
    -- slap action
	if commandName == 'ulx slap' then
	print( 'EraYaN: ', 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=slapper
		2=user targets
		3=dmg
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Slap' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Slap' ,key, value)
		end
	end
	end
	-- kick action
	if commandName == 'ulx kick' then
	print( 'EraYaN: ', 'Kicked someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=kicker
		2=user being kicked
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Kick' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Kick' ,key, value)
		end
	end

	end
	if commandName == 'ulx ban' then
	print( 'EraYaN: ', 'Banned someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=banned
		2=user being banned
		3=reason
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key2, value2 in pairs(value) do
				print( 'EraYaN: ', '\t\tSub-Table Ban' ,key2, value2)
			end		
		else
			print( 'EraYaN: ', 'Table Ban' ,key, value)
		end
	end

	end
end
hook.Add("ULibPostTranslatedCommand", "EraYaNCommandHook", commandHook)


-- player join (add to mysql database)
function playerJoinDB(ply)
	print( 'EraYaN: ', '---------------------A Player Joined---------------------' )
	erayan.doCheckUser(ply)
end
hook.Add("UCLAuthed", "EraYaNPlayerAuthedHook", playerJoinDB)