-- Short and sweet
if SERVER then
	include( "sqlbindings/init.lua" )
else
	include( "sqlbindings/cl_init.lua" )
end
