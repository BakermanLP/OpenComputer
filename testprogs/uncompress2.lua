--# Implement basic API's

--# Main Block --

local function Uncompress(str)
	local retstring = ''
	local multiplier = 0
	local special = ''
	local pos = 0
    local count = 0

    for st,sp in function() return string.find(str,' ',pos,true) end do
		if count % 2 == 0 then
            multiplier = string.sub(str,pos,st-1)
--			print("pos % 2 == 0")
--            print(string.sub(str,pos,st-1))
		else
--			print("pos % 2 != 0")
--            print(string.sub(str,pos,st-1))
            special=string.sub(str,pos,st-1)
            for i=1,multiplier do
                retstring=retstring..special
            end
		end	
        pos = sp + 1
        count = count + 1
    end

  return retstring
end

headercount=0
for Str in io.lines("./voxels-512-comp.txt") do
headercount=headercount+1
if headercount>5 then
    print(Uncompress(Str))
else
    print(Str)
end
end
