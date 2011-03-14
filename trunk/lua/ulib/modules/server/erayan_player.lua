function ULib.slap( ent, damage, power, nosound )
	print('Slap override')
end
-- way of overriding?

-- ban hook function
function slapHook(ply, commandName, translated_args)
if commandName == 'slap' then
print( 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
end
hook.Add("ULibPostTranslatedCommand", "EraYaNSlapHook", slapHook) -- or is there a ulib/ulx alternative


-- player join (add to mysql database)
function playerJoinDB(ply)
	print( 'player Joined' )
end
hook.Add("UCLAuthed", "HookName", playerJoinDB) -- or is there a ulib/ulx alternative
end