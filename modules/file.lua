local FileManager = {}
FileManager.__index = FileManager
FileManager.defaultFolder = "AE-Library"

local function safe(f, ...)
	local ok, result = pcall(f, ...)
	if not ok then
		warn("[AE-FM][ERROR]", result)
		return nil
	end
	return result
end

local function joinPath(...)
	return table.concat({...}, "/")
end

local function fileExists(path)
	return isfile(path)
end

local function folderExists(path)
	return isfolder(path)
end

local function ensureFolder(path)
	if not folderExists(path) then
		return safe(makefolder, path)
	end
	return true
end

local function getFullPath(file, customFolder)
	local folder = customFolder or FileManager.defaultFolder
	return joinPath(folder, file)
end

function FileManager:init(customFolder)
	if customFolder then
		FileManager.defaultFolder = customFolder
	end
	ensureFolder(FileManager.defaultFolder)
	return self
end

function FileManager:create(file, content)
	local path = getFullPath(file)
	if fileExists(path) then return false end
	return safe(writefile, path, content or "")
end

function FileManager:write(file, content)
	local path = getFullPath(file)
	return safe(writefile, path, content)
end

function FileManager:append(file, content)
	local old = self:read(file) or ""
	return self:write(file, old .. content)
end

function FileManager:read(file)
	local path = getFullPath(file)
	if not fileExists(path) then return nil end
	return safe(readfile, path)
end

function FileManager:delete(file)
	local path = getFullPath(file)
	if fileExists(path) then
		return safe(delfile, path)
	end
	return false
end

function FileManager:rename(oldName, newName)
	local oldPath = getFullPath(oldName)
	local newPath = getFullPath(newName)
	if not fileExists(oldPath) then return false end
	local content = self:read(oldName)
	local created = self:write(newName, content)
	if created then
		self:delete(oldName)
		return true
	end
	return false
end

function FileManager:list()
	local files = safe(listfiles, FileManager.defaultFolder)
	if not files then return {} end
	for i, v in ipairs(files) do
		files[i] = v:match("^.+/(.+)$") or v
	end
	return files
end

function FileManager:exists(file)
	return fileExists(getFullPath(file))
end

function FileManager:getSize(file)
	local content = self:read(file)
	return content and #content or 0
end

function FileManager:getJSON(file)
	local raw = self:read(file)
	if not raw then return nil end
	local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	return ok and decoded or nil
end

function FileManager:writeJSON(file, tbl)
	local ok, encoded = pcall(function() return game:GetService("HttpService"):JSONEncode(tbl) end)
	if not ok then return false end
	return self:write(file, encoded)
end

function FileManager:mkdir(folderName)
	local full = joinPath(FileManager.defaultFolder, folderName)
	if not folderExists(full) then
		return safe(makefolder, full)
	end
	return true
end

function FileManager:rmdir(folderName)
	local full = joinPath(FileManager.defaultFolder, folderName)
	return safe(delfolder, full)
end

function FileManager:getFullPath(file)
	return getFullPath(file)
end

return setmetatable({}, FileManager):init()