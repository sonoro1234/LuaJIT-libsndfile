local sndfile = require"sndfile_ffi"
local ffi = require"ffi"

print(sndfile.version_string())

local sf = sndfile.Sndfile([[african_room.wav]])

local fr_out = 1024 --*2--100
local data_out = ffi.new("float[?]",sf:channels()*fr_out)
sf:resampler_create()

--open write
local sf2 = sndfile.Sndfile([[./sample_conv.aiff]],"w",sf:samplerate(),sf:channels(),sndfile.SF_FORMAT_AIFF+sndfile.SF_FORMAT_FLOAT)

print"going"
while true do
	local ratio = 1.5-- + 0.06*math.sin(2*math.pi*totalread/40000)
	local readfr = sf:resampler_read( ratio, fr_out, data_out)
	if readfr ==0 then
		break
	end
	totalread = totalread + readfr
	sf2:writef_float(data_out,readfr)
end
end
print"ended"



