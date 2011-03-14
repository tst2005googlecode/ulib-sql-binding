-- slap/kick hook function
function commandHook(ply, commandName, translated_args)
    -- slap action
	if commandName == 'ulx slap' then
	print( 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=slapper
		2=user args
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key, value in pairs(translated_args) do
				print( 'Sub-Table Slap' ,key, value)
			end		
		else
			print( 'Table Slap' ,key, value)
		end
	end
	end
	-- kick action
	if commandName == 'ulx kick' then
	print( 'Kicked someone, printed using ULibPostTranslatedCommand hook' )
	--[[
	translated args
		1=kicker
		2=user being kicked	
	]]--
	for key, value in pairs(translated_args) do
		if type(value) == 'table' then
			for key, value in pairs(translated_args) do
				print( 'Sub-Table Kick' ,key, value)
			end		
		else
			print( 'Table Kick' ,key, value)
		end
	end

	end
end
hook.Add("ULibPostTranslatedCommand", "EraYaNCommandHook", commandHook)


-- player join (add to mysql database)
function playerJoinDB(ply)
	print( '---------------------A Player Joined---------------------' )
end
hook.Add("UCLAuthed", "PlayerAuthedHook", playerJoinDB)