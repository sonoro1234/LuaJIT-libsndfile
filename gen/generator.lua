
----------------------------------do it
--sndfile.h.in to sndfile.h
local cp2c = require"cpp2ffi"
local header = cp2c.read_data("../libsndfile/src/sndfile.h.in")
header = header:gsub("@TYPEOF_SF_COUNT_T@","int64_t")
header = header:gsub("@SF_COUNT_MAX@","0x7FFFFFFFFFFFFFFFLL")
cp2c.save_data("./sndfile.h",header)

--preparse sndfile.h
local cdefs = {}

cp2c.save_data("./outheader.h",[[#include <sndfile.h>]])
--local pipe,err = io.popen([[gcc -E -dD -I ../libsndfile/src/ ./outheader.h]],"r")
local pipe,err = io.popen([[gcc -E -dD -I . ./outheader.h]],"r")
if not pipe then
    error("could not execute gcc "..err)
end

local defines = {}
for line in cp2c.location(pipe,{[[sndfile.-]]},defines) do
    --local line = strip(line)
	table.insert(cdefs,line)
end
pipe:close()
os.remove"./outheader.h"

--save preparse
local txt = table.concat(cdefs,"\n")
--local txt2 = table.concat(cdefs," rayo ")
cp2c.save_data("./cpreout.txt",txt)

--parseItems
local itemarr,items = cp2c.parseItems(txt)
local cdefs = {}
for i,it in ipairs(itemarr) do
	table.insert(cdefs,it.item)
end

--get some defines
--for k,v in pairs(defines) do print("define",k,v) end
local deftab = {}
local ffi = require"ffi"
ffi.cdef(table.concat(cdefs,""))
local wanted_strings = {".+"}--"^SDL","^AUDIO_","^KMOD_","^RW_"}
for i,v in ipairs(defines) do
	local wanted = false
	for _,wan in ipairs(wanted_strings) do
		if (v[1]):match(wan) then wanted=true; break end
	end
	if wanted then
		local lin = "static const int "..v[1].." = " .. v[2] .. ";"
		local ok,msg = pcall(function() return ffi.cdef(lin) end)
		if not ok then
			print("skipping def",lin)
			print(msg)
		else
			table.insert(deftab,lin)
		end
	end
end

local special =[[

typedef struct SNDFILE_ref
{
	SNDFILE *sf ;
	SF_INFO sfinfo[1] ;
	int mode ;
} SNDFILE_ref;

]]


----------------get format enums
local format_enums = {}
for i,enum in ipairs(items.enum_re) do
	local inner = enum:match("%b{}"):sub(2,-2)
	for name, value in inner:gmatch("(SF_FORMAT%S*)%s*=%s*([^,%s]*)") do
		print(name,value,tonumber(value))
		assert(not format_enums[tonumber(value)])
		format_enums[tonumber(value)] = name
	end
end
local format_enums_str = cp2c.serializeTable("formats",format_enums)
--get manuals
local sndfile_manual = cp2c.read_data("./sndfile_ffi_manual.lua")

--output sndfile_ffi.lua
local sdlstr = [[
local ffi = require"ffi"

--uncomment to debug cdef calls]]..
"\n---[["..[[

local ffi_cdef = ffi.cdef
ffi.cdef = function(code)
    local ret,err = pcall(ffi_cdef,code)
    if not ret then
        local lineN = 1
        for line in code:gmatch("([^\n\r]*)\r?\n") do
            print(lineN, line)
            lineN = lineN + 1
        end
        print(err)
        error"bad cdef"
    end
end
]].."--]]"..[[

ffi.cdef]].."[["..table.concat(cdefs,"").."]]"..[[

ffi.cdef]].."[["..table.concat(deftab,"\n").."]]"..[[

ffi.cdef]].."[["..special.."]]"..[[
]]..format_enums_str..sndfile_manual

cp2c.save_data("./sndfile_ffi.lua",sdlstr)
cp2c.copyfile("./sndfile_ffi.lua","../sndfile_ffi.lua")
-------------------------------
--[[
require"anima.utils"
for i=1,#items[function_re] do
--for i=11,11 do
 local defT = parseFunction(items[function_re][i],i)
--prtable(defT)
end

print"typedefs--------------------------------------"
for i=1,#items[typedef_re] do print(items.typedef_re[i]) end
print"functypedefs--------------------------------------"
for i=1,#items[functypedef_re] do print(items.functypedef_re[i]) end
print"struct--------------------------------------"
for i=1,#items[struct_re] do print(items[struct_re][i]) end
print"union--------------------------------------"
for i=1,#items[union_re] do print(items[union_re][i]) end
print"enum--------------------------------------"
for i=1,#items[enum_re] do print(items[enum_re][i]) end
print"vardef--------------------------------------"
for i=1,#items[vardef_re] do print(items[vardef_re][i]) end

--]]
