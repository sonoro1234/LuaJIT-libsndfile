-------------samplerate conversion
local srconv = require"samplerate"

ffi_cdef[[
typedef struct RESAMPLER RESAMPLER;
typedef struct SNDFILE_ref
{
    SNDFILE *sf ;
    SF_INFO sfinfo[1] ;
    int mode ;
    RESAMPLER *resampler;
} SNDFILE_ref;

typedef struct RESAMPLER
{
  SRC_STATE *src_state;
  unsigned long resampler_frames;
  float * resampler_buffer;
  double ratio;
  SNDFILE_ref *sf;
} RESAMPLER;

]]


local lib = ffi.load"sndfile"

local M = {C=lib, srconv=srconv}

M.formats = formats

local function ffi_string(str)
    if str==nil then
        return ""
    else
        return ffi.string(str)
    end
end

local function input_cb_orig(cb_data, out)
  local resam = ffi.cast("RESAMPLER *", cb_data)
  local readframes = resam.sf:readf_float(resam.resampler_buffer, resam.resampler_frames)
  out[0] = resam.resampler_buffer
  return readframes
end
M.resampler_input_cb = input_cb_orig

local RESAMPLER = {}
RESAMPLER.__index = RESAMPLER
function RESAMPLER:__new(sf,fr_read, converter,input_cb,ratio )
	input_cb = input_cb or input_cb_orig
    local ret = ffi.new"RESAMPLER"
    fr_read = fr_read or 1024
    converter = converter or srconv.SRC_SINC_BEST_QUALITY
    local buf = ffi.new("float[?]",fr_read * sf:channels())
    ret.sf = sf
    ret.resampler_frames = fr_read
    ret.resampler_buffer = buf
    ret.ratio = ratio or 1
    local err = ffi.new"int[1]"
    local src_state = srconv.src_callback_new(input_cb, converter, sf:channels(), err, ret)
    if src_state == nil then 
        local errstr = ffi_string(srconv.src_strerror(err[0]))
        error(errstr,2) 
    end
    ret.src_state = src_state
    ffi.gc(ret,function(t) ret:delete(buf) end) --anchor buf
    return ret
end
function RESAMPLER:delete()
    ffi.gc(self,nil)
    if self.src_state~=nil then
        srconv.src_delete(self.src_state)
    end
end
function RESAMPLER:set_ratio(ratio)
    self.ratio = ratio
    srconv.src_set_ratio(self.src_state, ratio)
end
function RESAMPLER:read(data_out, fr_out, ratio)
    if ratio then
        self.ratio = ratio
    end
    local readfr = srconv.src_callback_read(self.src_state, self.ratio, fr_out, data_out)
    local err = srconv.src_error(self.src_state)
    if err~=0 then 
        local errstr = ffi_string(srconv.src_strerror(err))
        error("RESAMPLER read error"..errstr,2) 
    end
    return readfr
end
function RESAMPLER:readf_float(data_out, fr_out, ratio)
    return self:read(data_out, fr_out, ratio)
end
function RESAMPLER:readf_int(data_out, fr_out, ratio)
    local len = fr_out*self.sf:channels()
    local bufferf = ffi.new("float[?]", len)
    local readfr = self:read(bufferf, fr_out, ratio)
    srconv.src_float_to_int_array (bufferf, data_out,len)
    return readfr
end
function RESAMPLER:readf_short(data_out, fr_out, ratio)
    local len = fr_out*self.sf:channels()
    local bufferf = ffi.new("float[?]", len)
    local readfr = self:read(bufferf, fr_out, ratio)
    srconv.src_float_to_short_array(bufferf, data_out,len)
    return readfr
end
function RESAMPLER:seek(frame_count,whence)
    srconv.src_reset(self.src_state)
    return self.sf:seek(frame_count,whence)
end
function RESAMPLER:reset()
    return srconv.src_reset(self.src_state)
end
M.RESAMPLER = ffi.metatype("RESAMPLER",RESAMPLER)

local Sndfile = {}
Sndfile.__index = Sndfile
function Sndfile.__new(tt,filename,mode,sr,ch,format)

    local sndfile_ref = ffi.new"SNDFILE_ref"
    sndfile_ref.sfinfo[0].samplerate = sr or 0
    sndfile_ref.sfinfo[0].channels = ch or 0
    sndfile_ref.sfinfo[0].format = format or 0
    
    if mode == nil or mode == "r" then
        mode = lib.SFM_READ
    elseif mode == "w" then
        mode = lib.SFM_WRITE
    elseif mode == "rw" then
        mode = lib.SFM_RDWR
    end
    sndfile_ref.mode = mode
    local sf = lib.sf_open(filename,mode,sndfile_ref.sfinfo)
    sndfile_ref.sf = sf
    if sf==nil then
        error(ffi_string(lib.sf_strerror(nil)).." "..filename, 2)
    end
    ffi.gc(sndfile_ref,function(t) return sndfile_ref.close(t,sf) end)
    return sndfile_ref
end
function Sndfile:close()
    ffi.gc(self,nil)
    local ret = lib.sf_close(self.sf)
    if ret~=0 then
        error(ffi_string(lib.sf_error_number(ret)),2)
    end
    self.sf = nil
end
function Sndfile:frames()
    return self.sfinfo[0].frames
end
function Sndfile:channels()
    return self.sfinfo[0].channels
end
function Sndfile:format()
    local form = self.sfinfo[0].format
    local formM = bit.band(form,lib.SF_FORMAT_TYPEMASK)
    local formS = bit.band(form,lib.SF_FORMAT_SUBMASK)
    return form, formats[formM],formats[formS]
end
function Sndfile:samplerate()
    return self.sfinfo[0].samplerate
end
function Sndfile:seek(frame_count,whence)
    return lib.sf_seek(self.sf,frame_count,whence or lib.SF_SEEK_SET)
end

function Sndfile:readf_double(buffer,frames)
    return lib.sf_readf_double(self.sf,buffer,frames)
end
function Sndfile:readf_float(buffer,frames)
    return lib.sf_readf_float(self.sf,buffer,frames)
end
function Sndfile:readf_int(buffer,frames)
    return lib.sf_readf_int(self.sf,buffer,frames)
end
function Sndfile:readf_short(buffer,frames)
    return lib.sf_readf_short(self.sf,buffer,frames)
end

function Sndfile:read_double(buffer,items)
    return lib.sf_read_double(self.sf,buffer,items)
end
function Sndfile:read_float(buffer,items)
    return lib.sf_read_float(self.sf,buffer,items)
end
function Sndfile:read_int(buffer,items)
    return lib.sf_read_int(self.sf,buffer,items)
end
function Sndfile:read_short(buffer,items)
    return lib.sf_read_short(self.sf,buffer,items)
end

function Sndfile:writef_double(buffer,frames)
    return lib.sf_writef_double(self.sf,buffer,frames)
end
function Sndfile:writef_float(buffer,frames)
    return lib.sf_writef_float(self.sf,buffer,frames)
end
function Sndfile:writef_int(buffer,frames)
    return lib.sf_writef_int(self.sf,buffer,frames)
end
function Sndfile:writef_short(buffer,frames)
    return lib.sf_writef_short(self.sf,buffer,frames)
end

function Sndfile:write_double(buffer,items)
    return lib.sf_write_double(self.sf,buffer,items)
end
function Sndfile:write_float(buffer,items)
    return lib.sf_write_float(self.sf,buffer,items)
end
function Sndfile:write_int(buffer,items)
    return lib.sf_write_int(self.sf,buffer,items)
end
function Sndfile:write_short(buffer,items)
    return lib.sf_write_short(self.sf,buffer,items)
end
---------------
local t_double = ffi.typeof"double[]"
local t_float = ffi.typeof"float[]"
local t_short = ffi.typeof"short[]"
local t_int = ffi.typeof"int[]"
local istype = ffi.istype
local sizeof = ffi.sizeof

function Sndfile:readf(buffer)
    local bsize = sizeof(buffer)
    --print(buffer,bsize,type(buffer))
    local readfunc,frames
    local ch = self:channels()
    if istype(t_double,buffer) then
        readfunc = lib.sf_readf_double
        frames = bsize/sizeof"double"/ch
    elseif istype(t_float,buffer) then
        readfunc = lib.sf_readf_float
        frames = bsize/sizeof"float"/ch
    elseif istype(t_int,buffer) then
        readfunc = lib.sf_readf_int
        frames = bsize/sizeof"int"/ch
    elseif istype(t_short,buffer) then
        readfunc = lib.sf_readf_short
        frames = bsize/sizeof"short"/ch
    else
        error("unknown type of buffer in Sndfile:readf",2)
    end
    assert(math.floor(frames)==frames,"sizeof buffer is not multiple of channels and type")
    return readfunc(self.sf,buffer,frames)
end

function Sndfile:writef(buffer)
    local bsize = sizeof(buffer,nframes)
    --print(buffer,bsize,type(buffer))
    local readfunc,frames
    local ch = self:channels()
    if istype(t_double,buffer) then
        readfunc = lib.sf_writef_double
        frames = bsize/sizeof"double"/ch
    elseif istype(t_float,buffer) then
        readfunc = lib.sf_writef_float
        frames = bsize/sizeof"float"/ch
    elseif istype(t_int,buffer) then
        readfunc = lib.sf_writef_int
        frames = bsize/sizeof"int"/ch
    elseif istype(t_short,buffer) then
        readfunc = lib.sf_writef_short
        frames = bsize/sizeof"short"/ch
    else
        error("unknown type of buffer in Sndfile:writef",2)
    end
    assert(math.floor(frames)==frames,"sizeof buffer is not multiple of channels and type")
    nframes = nframes or frames
    local ret = readfunc(self.sf,buffer,nframes)
    assert(ret==nframes,"error writing file")
end

function Sndfile:resampler_create(fr_read, converter,inputcb)
    assert(self.resampler==nil, "resampler_create already used.")
    self.resampler = M.RESAMPLER(self,fr_read, converter,inputcb)
    return self.resampler
end



M.Sndfile = ffi.metatype("SNDFILE_ref",Sndfile)

function M.get_info(filename)
   local sf = M.Sndfile(filename)
   local info = {samplerate = sf.sfinfo[0].samplerate,
                channels = sf.sfinfo[0].channels,
                frames = sf.sfinfo[0].frames,
                format = sf.sfinfo[0].format
                }
    sf:close()
    return info
end
function M.version_string()
    return ffi_string(lib.sf_version_string())
end

function M.simple_format_count()
    local  count = ffi.new"int[1]"
    lib.sf_command (nil, lib.SFC_GET_SIMPLE_FORMAT_COUNT, count, ffi.sizeof("int")) ;
    return count[0]
end

function M.simple_format(n)
    local format_info = ffi.new"SF_FORMAT_INFO[1]"
    format_info[0].format = n
    local ret = lib.sf_command (nil, lib.SFC_GET_SIMPLE_FORMAT, format_info, ffi.sizeof(format_info[0]))
    if(ret~=0) then
        print("GET_SIMPLE_FORMAT",n,ffi_string(lib.sf_error_number(ret)))
        error("GET_SIMPLE_FORMAT",2)
    end
    return format_info[0]
end

function M.simple_formats()
    local count = M.simple_format_count()
    local ret = {}
    for i=0,count-1 do
        local finfo = M.simple_format(i)
        table.insert(ret,{format_en=formats[finfo.format], format=finfo.format,name=ffi_string(finfo.name),ext=ffi_string(finfo.extension)})
    end
    return ret
end

function M.major_format_count()
    local  count = ffi.new"int[1]"
    lib.sf_command (nil, lib.SFC_GET_FORMAT_MAJOR_COUNT, count, ffi.sizeof("int")) ;
    return count[0]
end

function M.major_format(n)
    local format_info = ffi.new"SF_FORMAT_INFO[1]"
    format_info[0].format = n
    local ret = lib.sf_command (nil, lib.SFC_GET_FORMAT_MAJOR, format_info, ffi.sizeof(format_info[0]))
    if(ret~=0) then
        print("SFC_GET_FORMAT_MAJOR",n,ffi_string(lib.sf_error_number(ret)))
        error("SFC_GET_FORMAT_MAJOR",2)
    end
    return format_info[0]
end

function M.major_formats()
    local count = M.major_format_count()
    local ret = {}
    for i=0,count-1 do
        local finfo = M.major_format(i)
        table.insert(ret,{format_en=formats[finfo.format], format=finfo.format,name=ffi_string(finfo.name),ext=ffi_string(finfo.extension)})
    end
    return ret
end

function M.format_subtype_count()
    local  count = ffi.new"int[1]"
    lib.sf_command (nil, lib.SFC_GET_FORMAT_SUBTYPE_COUNT, count, ffi.sizeof("int")) ;
    return count[0]
end

function M.format_subtype(n)
    local format_info = ffi.new"SF_FORMAT_INFO[1]"
    format_info[0].format = n
    local ret = lib.sf_command (nil, lib.SFC_GET_FORMAT_SUBTYPE, format_info, ffi.sizeof(format_info[0]))
    if(ret~=0) then
        print("SFC_GET_FORMAT_SUBTYPE",n,ffi_string(lib.sf_error_number(ret)))
        error("SFC_GET_FORMAT_SUBTYPE",2)
    end
    return format_info[0]
end

function M.format_subtypes(parent)
    local sfinfo = ffi.new"SF_INFO[1]"
    sfinfo[0].channels = 1 
    local count = M.format_subtype_count()
    local ret = {}
    for i=0,count-1 do
        local finfo = M.format_subtype(i)
        sfinfo[0].format = bit.bor(bit.band(parent or 0, lib.SF_FORMAT_TYPEMASK), finfo.format)
        if(lib.sf_format_check(sfinfo)~=0) then
            table.insert(ret,{format_en=formats[finfo.format], format=finfo.format,name=ffi_string(finfo.name)})
        end
    end
    return ret
end

setmetatable(M,{
__index = function(t,k)
    local ok,ptr = pcall(function(str) return lib["sf_"..str] end,k)
    if not ok then ok,ptr = pcall(function(str) return lib["SF_"..str] end,k) end
    if not ok then ok,ptr = pcall(function(str) return lib[str] end,k) end --some defines without sf_
    if not ok then error(k.." not found",2) end
    rawset(M, k, ptr)
    return ptr
end
})


return M