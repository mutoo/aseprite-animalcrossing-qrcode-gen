function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
 end

local outputDir = '../models'
local models = {'dress-half', 'dress-long', 'dress-no', 'shirt-half', 'shirt-long', 'shirt-no'}
for i, model in ipairs(models) do
    local vertex = {}
    local uvs = {}
    local normals = {}
    local faces = {}
    local obj = {}
    for line in io.lines('./'.. model .. '.obj') do
        local cmd = line:split(' ')
        if cmd[1] == 'o' then
            obj.name = cmd[2]
        elseif cmd[1] == 'v' then
            table.insert(vertex, {cmd[2], cmd[3], cmd[4]})
        elseif cmd[1] == 'vt' then
            table.insert(uvs, {cmd[2], cmd[3]})
        elseif cmd[1] == 'vn' then
            table.insert(normals, {cmd[2], cmd[3], cmd[4]})
        elseif cmd[1] == 'f' then
            local v1 = cmd[2]:split('/')
            local v2 = cmd[3]:split('/')
            local v3 = cmd[4]:split('/')
            table.insert(faces, {v1, v2, v3})
        end
    end
    print(obj.name, #vertex, #normals, #uvs, #faces)
end
