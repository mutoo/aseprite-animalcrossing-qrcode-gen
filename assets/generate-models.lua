require('./data-dumper')

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function tonumbers(t)
    local ret = {}
    for i, v in ipairs(t) do
        ret[i] = tonumber(v)
    end
    return ret
end

function add(t, n)
    local ret = {}
    for i, v in ipairs(t) do
        ret[i] = v + n[i]
    end
    return ret
end

function substract(t, n)
    local ret = {}
    for i, v in ipairs(t) do
        ret[i] = v - n[i]
    end
    return ret
end

local vertex, uvs, normals, faces, obj
local offset = { 0, 0, 0 }
local outputDir = '../models'

function outputObj(obj)
    obj.vertex = vertex
    obj.normals = normals
    obj.uvs = uvs
    obj.faces = faces
    print(obj.name, #vertex, #normals, #uvs, #faces)
    local objToLua = DataDumper(obj, nil, true, 0)
    local filename = obj.name:lower()
    filename = table.concat(filename:split('_'), '-')
    local outputFilepath = outputDir .. '/'  .. filename .. '.lua'
    local output = assert(io.open(outputFilepath, 'w'), 'cant write to file: ' .. outputFilepath)
    output:write(objToLua)
    output:close()
end

for line in io.lines('./models.obj') do
    local cmd = line:split(' ')
    if cmd[1] == 'o' then
        -- finilise previous obj
        if obj then
            offset = add(offset, {#vertex,#uvs,#normals})
            outputObj(obj)
        end
        -- create new object
        obj = {}
        obj.name = cmd[2]
        vertex = {}
        uvs = {}
        normals = {}
        faces = {}
    elseif cmd[1] == 'v' then
        table.insert(vertex, tonumbers({ cmd[2], cmd[3], cmd[4] }))
    elseif cmd[1] == 'vt' then
        table.insert(uvs, tonumbers({ cmd[2], cmd[3] }))
    elseif cmd[1] == 'vn' then
        table.insert(normals, tonumbers({ cmd[2], cmd[3], cmd[4] }))
    elseif cmd[1] == 'f' then
        local v1 = substract(tonumbers(cmd[2]:split('/')), offset)
        local v2 = substract(tonumbers(cmd[3]:split('/')), offset)
        local v3 = substract(tonumbers(cmd[4]:split('/')), offset)
        table.insert(faces, { v1, v2, v3 })
    end
end
-- finilise last obj
if obj then outputObj(obj) end
