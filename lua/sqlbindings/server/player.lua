function ULib.slap( ent, damage, power, nosound )
	Msg('Slap override')
end
-- way of overriding?

-- ban hook function
function slapHook(ply, commandName, translated_args)
if commandName == 'slap' then
Msg( 'Slapped someone, printed using ULibPostTranslatedCommand hook' )
end
hook.Add("ULibPostTranslatedCommand", "EraYaNSlapHook", slapHook) -- or is there a ulib/ulx alternative


-- player join (add to mysql database)
function playerJoinDB(ply)
	Msg( 'player Joined' )
end
hook.Add("UCLAuthed", "HookName", playerJoinDB) -- or is there a ulib/ulx alternative