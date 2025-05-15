local HttpService = game:GetService("HttpService")

local Config = {}
Config.folder = "AE-Library"
Config.file = Config.folder .. "/config.json"
Config.data = {}

local function ensure()
    if not isfolder(Config.folder) then
        local ok, err = pcall(function() makefolder(Config.folder) end)
        if not ok then warn("[AE] Error al crear carpeta:", err) end
    end

    if not isfile(Config.file) then
        local ok, err = pcall(function() writefile(Config.file, "{}") end)
        if not ok then warn("[AE] Error al crear archivo:", err) end
    end

    local success, content = pcall(function()
        return HttpService:JSONDecode(readfile(Config.file))
    end)
    if success then
        Config.data = content
    else
        warn("[AE] Error al decodificar JSON:", content)
        Config.data = {}
    end
end

local function save()
    local success, result = pcall(function()
        writefile(Config.file, HttpService:JSONEncode(Config.data))
    end)
    if not success then
        warn("[AE] Error al guardar configuración:", result)
    end
end

local function deepGet(tbl, keys)
    for _, key in ipairs(keys) do
        if type(tbl) ~= "table" or tbl[key] == nil then return nil end
        tbl = tbl[key]
    end
    return tbl
end

local function deepSet(tbl, keys, value)
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(tbl[key]) ~= "table" then
            tbl[key] = {}
        end
        tbl = tbl[key]
    end
    tbl[keys[#keys]] = value
end

local function deepRemove(tbl, keys)
    for i = 1, #keys - 1 do
        tbl = tbl[keys[i]]
        if type(tbl) ~= "table" then return end
    end
    tbl[keys[#keys]] = nil
end

function Config:set(key, value)
    local path = typeof(key) == "table" and key or { key }
    deepSet(Config.data, path, value)
    save()
end

function Config:get(key)
    local path = typeof(key) == "table" and key or { key }
    return deepGet(Config.data, path)
end

function Config:has(key)
    return self:get(key) ~= nil
end

function Config:add(key, amount)
    local current = self:get(key)
    if typeof(current) ~= "number" then current = 0 end
    self:set(key, current + amount)
end

function Config:remove(key)
    local path = typeof(key) == "table" and key or { key }
    deepRemove(Config.data, path)
    save()
end

function Config:reset()
    Config.data = {}
    save()
end

function Config:toggle(key)
    local val = self:get(key)
    if typeof(val) ~= "boolean" then val = false end
    self:set(key, not val)
end

function Config:append(key, value)
    local list = self:get(key)
    if typeof(list) ~= "table" then list = {} end
    table.insert(list, value)
    self:set(key, list)
end

function Config:pop(key)
    local list = self:get(key)
    if typeof(list) ~= "table" then return end
    table.remove(list, #list)
    self:set(key, list)
end

function Config:keys(key)
    local val = self:get(key)
    if typeof(val) ~= "table" then return {} end
    local k = {}
    for i, _ in pairs(val) do table.insert(k, i) end
    return k
end

ensure()

return Config
