require("mysqloo")

if not erayan then
	erayan = {}
end

erayan.config = {
	hostname = "erayan.eu";
	username = "dehaantj_ulibulx";
	password = "tub561vihis3";
	database = "dehaantj_ulib_ulx";
	website  = "blackbox.erayan.eu";
	portnumb = 3306;
	server = "TTT";
	version = "0.9.1.0";
	silent = true
}
hook.Add("Initialize", "EraYaNVersion", function() erayan.imsg('Version: '..erayan.config.version, false) end)
function erayan.table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      Msg(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        Msg(string.format("[%s] => table\n", tostring (key)));
        Msg(string.rep (" ", indent+4)) -- indent it
        Msg("(\n");
        erayan.table_print (value, indent + 7, done)
        Msg(string.rep (" ", indent+4)) -- indent it
        Msg(")\n");
      else
        Msg(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    Msg(tostring(tt) .. "\n")
  end
end

function erayan.pmsg(str, dashes, ...)
	if erayan.config.silent then return end
	if dashes then
		print( 'EraYaN: ', '------------------'..str..'------------------' )
	else
		print( 'EraYaN: ', str, ...)
	end
end

function erayan.imsg(str, dashes, ...)
	if dashes then
		print( 'EraYaN: ', '------------------'..str..'------------------' )
	else
		print( 'EraYaN: ', str, ...)
	end
end