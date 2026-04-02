function Init()
	local file = io.open("fvipers_script_probe.txt", "w")
	if file then
		file:write("fvipers.lua Init called\n")
		file:close()
	end
end
