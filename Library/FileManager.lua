local _isfile = isfile or (debug and debug.isfile) or function() end
local _readfile = readfile or (debug and debug.readfile) or function() end
local _writefile = writefile or (debug and debug.writefile) or function() end
local _delfile = delfile or (debug and debug.delfile) or function() end
local _listfiles = listfiles or (debug and debug.listfiles) or function() end
local _isfolder = isfolder or (debug and debug.isfolder) or function() end
local _makefolder = makefolder or (debug and debug.makefolder) or function() end
local _delfolder = delfolder or (debug and debug.delfolder) or function() end

local HttpService = game:GetService("HttpService")

local FileManager = {} do
    function FileManager:GetFolder(value)
        if not _isfolder(value) then
            _makefolder(value)
        end
    end

    function FileManager:DeleteFolder(value)
        if _isfolder(value) then
            _delfolder(value)
        end
    end

    function FileManager:GetFile(value, data)
        if not _isfile(value) then
            if type(data) == "table" then
                _writefile(value, HttpService:JSONEncode(data))
            else
                _writefile(value, data or "")
            end
        end
    end

    function FileManager:WriteFile(value, data)
        if type(data) == "table" then
            _writefile(value, HttpService:JSONEncode(data))
        else
            _writefile(value, data or "")
        end
    end

    function FileManager:DeleteFile(value)
        if _isfile(value) then
            _delfile(value)
        end
    end

    function FileManager:ReadFile(value, format)
        if _isfile(value) then
            if format == "table" then
                return HttpService:JSONDecode(_readfile(value))
            else
                return _readfile(value)
            end
        end
    end

    function FileManager:ListFiles(value, format)
        local fileList = {}
        for _, filePath in next, _listfiles(value) do
            local name = filePath:match("[^/\\]+$")
            if format == "json" and name:match("%.json$") then
                name = name:sub(1, -6)
            elseif format == "lua" and name:match("%.lua$") then
                name = name:sub(1, -5)
            end
            table.insert(fileList, name or filePath)
        end
        return fileList
    end
end

return FileManager