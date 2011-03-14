-- slap/kick hook function
function slapHook(ply, commandName, translated_args)
    -- slap action
	if commandName == 'ulx slap' then
	print( 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
	for key, value in pairs(translated_args) do
		print("Table entry #"..key..": "..value)
	end
	end
	-- kick action
	if commandName == 'ulx kick' then
	print( 'Kicked someone, printed using ULibPostTranslatedCommand hook' )
	for key, value in pairs(translated_args) do
		print("Table entry #"..key..": "..value)
	end

	end
end
hook.Add("ULibPostTranslatedCommand", "EraYaNSlapHook", slapHook) -- or is there a ulib/ulx alternative


-- player join (add to mysql database)
function playerJoinDB(ply)
	print( '---------------------A Player Joined---------------------' )
end
hook.Add("UCLAuthed", "HookName", playerJoinDB) -- or is there a ulib/ulx alternative