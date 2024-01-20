local CustomCrypt = {}
CustomCrypt.__index = CustomCrypt

function CustomCrypt.new()
    local self = setmetatable({}, CustomCrypt)
    self.old = 0
    return self
end

function CustomCrypt:CustomCrypt(t)
    local out = {}
    
    for a = 1, #(t) do  
        local byt = string.byte(string.sub(t, a, a))
        local new = (byt + self.old) % 256
        
        local new2
        if a == 13 then
            new2 = 10 ^ (math.abs(new))
        else
            new2 = 10 ^ (math.abs(new) - 0xf)
        end
        
        out[a] = new2 + 0x10105
        self.old = byt
    end 
    
    return out
end

function CustomCrypt:deCustomCrypt(t)
    local txt = ""
    
    for i = 1, #t do
        local new2 = t[i] - 0x10105
        new2 = math.log10(math.abs(new2))
        
        local new = (new2 - self.old) % 256 + (i ~= 13 and 0xf or 0)
        self.old = new
        
        txt = txt .. string.char(new)
    end
    
    return txt
end

function CustomCrypt.base64Enc(self, data)
    if not data then return end
    
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    
    return table.concat(self:CustomCrypt((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0')
        end
        return r;
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == '1' and 2^(6-i) or 0)
        end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1]), "!")
end

function CustomCrypt.base64Dec(self, data)
    if not data then return end
    
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    
    data = string.gsub(self:deCustomCrypt(data:split("!")), '[^'..b..'=]', '')
    
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0')
        end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0)
        end
        return string.char(c)
    end))
end

return CustomCrypt
