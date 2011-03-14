-- slap/kick hook function
function commandHook(ply, commandName, translated_args)
    -- slap action
	if commandName == 'ulx slap' then
	print( 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
	for key, value in pairs(translated_args) do
		print( 'Table Slap' ,key, value)
	end
	end
	-- kick action
	if commandName == 'ulx kick' then
	print( 'Kicked someone, printed using ULibPostTranslatedCommand hook' )
	for key, value in pairs(translated_args) do
		print( 'Table Kick' ,key, value)
	end

	end
end
hook.Add("ULibPostTranslatedCommand", "EraYaNCommandHook", commandHook)


-- player join (add to mysql database)
function playerJoinDB(ply)
	print( '---------------------A Player Joined---------------------' )
end
hook.Add("UCLAuthed", "PlayerAuthedHook", playerJoinDB)