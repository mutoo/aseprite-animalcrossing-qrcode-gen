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

local outputDir = '../models'
local models = { 'dress-half-sleeve', 'dress-long-sleeve', 'dress-no-sleeve', 'shirt-half-sleeve', 'shirt-long-sleeve', 'shirt-no-sleeve' }
for _, model in ipairs(models) do
    local vertex = {}
    local uvs = {}
    local normals = {}
    local faces = {}
    local obj = {}
    for line in io.lines('./' .. model .. '.obj') do
        local cmd = line:split(' ')
        if cmd[1] == 'o' then
            obj.name = cmd[2]
        elseif cmd[1] == 'v' then
            table.insert(vertex, tonumbers({ cmd[2], cmd[3], cmd[4] }))
        elseif cmd[1] == 'vt' then
            table.insert(uvs, tonumbers({ cmd[2], cmd[3] }))
        elseif cmd[1] == 'vn' then
            table.insert(normals, tonumbers({ cmd[2], cmd[3], cmd[4] }))
        elseif cmd[1] == 'f' then
            local v1 = tonumbers(cmd[2]:split('/'))
            local v2 = tonumbers(cmd[3]:split('/'))
            local v3 = tonumbers(cmd[4]:split('/'))
            table.insert(faces, { v1, v2, v3 })
        end
    end
    obj.vertex = vertex
    obj.normals = normals
    obj.uvs = uvs
    obj.faces = faces
    print(obj.name, #vertex, #normals, #uvs, #faces)
    local objToLua = DataDumper(obj, nil, true, 0)
    local outputFilepath = outputDir .. '/' .. model .. '.lua'
    local output = assert(io.open(outputFilepath, 'w'), 'cant write to file: ' .. outputFilepath)
    output:write(objToLua)
    output:close()
end
