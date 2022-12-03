local StartPosition = StartPosition or SysTime() -- Cached SysTime = 1654
local NextSongTime = NextSongTime or nil -- Cached SysTime = 1654 SysTime = 1690 Nexttracklength = 611

local timestamp = StartPosition - SysTime() -- Cached SysTime = 1654 SysTime = 2200 Nexttracklength = 611

// your onclick event handler
for _, v in ipairs (music_left[v.name]) do
	if NextSongTime <= StartPosition then
	    table.remove(music_left[v.name], 1)
	    StartPosition = SysTime()
	    NextSongTime = StartPosition + Nexttracklength + 1
	end
end