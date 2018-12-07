local sndfile = require"sndfile_ffi"
local ffi = require"ffi"


print(sndfile.version_string())
local  buffer =ffi.new("char[128]") ;
sndfile.sf_command (nil, sndfile.SFC_GET_LIB_VERSION, buffer, ffi.sizeof (buffer)) ;
print("version",ffi.string(buffer))

--[[
print("simple version count",sndfile.simple_format_count())
print(sndfile.simple_format(0))
print"simple formats"
prtable(sndfile.simple_formats())
print"major formats"
prtable(sndfile.major_formats())
print"subtype formats"
prtable(sndfile.format_subtypes())
--]]

--list formats
--[[
local majfor = sndfile.major_formats()
for i,v in ipairs(majfor) do
	print("major format:",v.name,v.format_en)
	local subf = sndfile.format_subtypes(v.format)
	for j,w in ipairs(subf) do
		print("\tsubtype:",w.name,w.format_en)
	end
end
--]]
---copy file changing format
local sf = sndfile.Sndfile([[african_room.wav]])

print(sf:channels(),sf:frames(),sf:samplerate(),sf:format())

local sf2 = sndfile.Sndfile([[./sample_conv.aiff]],"w",sf:samplerate(),sf:channels(),sndfile.SF_FORMAT_AIFF+sndfile.SF_FORMAT_FLOAT)
--copy data
print"copy data"
local data = ffi.new("double[?]",sf:channels()*1024)

while true do
	local readcount = sf:readf_double(data,1024)
	--print(readcount)
	if readcount == 0 then break end
	sf2:writef_double(data,readcount)
end

sf2:close()
sf:close()


