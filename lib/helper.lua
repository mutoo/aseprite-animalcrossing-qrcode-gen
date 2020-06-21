local qrencode = dofile("./qrencode.lua")
local mat = dofile('./matrix.lua')

-- insert multi values into table
function push(t, ...)
    for i, v in ipairs({ ... }) do
        table.insert(t, v)
    end
end

-- pad with zero
function padding(n, ...)
    local args = { ... }
    local diff = n - #args
    for i = 1, diff do
        table.insert(args, 0)
    end
    return table.unpack(args)
end

-- the alpha index is not packed in the data layout
function shiftWithAlpha(p, a)
    if p < a then
        return p
    end
    if p == a then
        return 0x0f
    end
    if p > a then
        return p - 1
    end
end

-- padding ascii to utf16
function utf16(...)
    local str = { ... }
    local ret = {}
    for _, c in ipairs(str) do
        table.insert(ret, c)
        table.insert(ret, 0)
    end
    return table.unpack(ret)
end

-- extract data block from pixels
function getDataBlock(pixels, cols, x, y, w, h)
    local data = {}
    for r = 0, h - 1 do
        for c = 0, w - 1, 2 do
            local i = (y + r) * cols + (x + c)
            table.insert(data, pixels[i] + pixels[i + 1] * 16)
        end
    end
    return table.unpack(data)
end

-- generate qrcode matrix
function getQRcodeMatrix(bitstr, hint)
    local ok, ret = qrencode.qrcode(bitstr, 2, 4, hint)
    assert(ok, ret)
    return ret
end

function getTypeFromInputs(inputs)
    local type = 9 -- default type
    if inputs.dress then
        type = 0
    elseif inputs.shirt then
        type = 3
    end
    if inputs.long then
        type = type + 0 -- Fullsleeve
    elseif inputs.short then
        type = type + 1 -- Halfsleeve
    elseif inputs.sleeveless then
        type = type + 2 -- Sleeveless
    end
    if inputs.hornedHat then
        type = 6 -- Plain pattern (easel)
    elseif inputs.cap then
        type = 7 -- Knit Cap
    elseif inputs.paint then
        type = 9 -- Horned Hat
    end
    return type
end

-- check if p2 on the right side of line p0p1
-- p0, p1, p2 in counter-clock order
function edge(p0, p1, p2)
    return (p1[1] - p0[1]) * (p2[2] - p0[2]) - (p2[1] - p0[1]) * (p1[2] - p0[2])
end

-- create buffer with filling
function createBuffer(size, fill)
    local buffer = {}
    for i = 0, size - 1 do
        buffer[i] = fill
    end
    return buffer
end

-- create rotation matrix on z axis
function rotateZ(a)
    return mat({
        { math.cos(a), -math.sin(a), 0, 0 },
        { math.sin(a), math.cos(a), 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 },
    })
end

-- create rotation matrix on x axis
function rotateX(a)
    return mat({
        { 1, 0, 0, 0 },
        { 0, math.cos(a), -math.sin(a), 0 },
        { 0, math.sin(a), math.cos(a), 0 },
        { 0, 0, 0, 1 },
    })
end

-- create rotation matrix on y axis
function rotateY(a)
    return mat({
        { math.cos(a), 0, math.sin(a), 0 },
        { 0, 1, 0, 0 },
        { -math.sin(a), 0, math.cos(a), 0 },
        { 0, 0, 0, 1 },
    })
end

-- create perspective matrix
function perspective(n, f, t, b, r, l)
    return mat({
        { 2 * n / (r - l), 0, (r + l) / (r - l), 0 },
        { 0, 2 * n / (t - b), (t + b) / (t - b), 0 },
        { 0, 0, -(f + n) / (f - n), -(2 * f) / (f - n) },
        { 0, 0, -1, 0 },
    })
end

-- transform vec1x3 with matrix4x4 and return vec1x3
function transform(matrix, vec)
    local vecMat = mat({ vec[1], vec[2], vec[3], 1 })
    local transformed = matrix * vecMat
    local w = transformed[4][1]
    return { transformed[1][1] / w, transformed[2][1] / w, transformed[3][1] / w }
end

-- normalize a vec1x3
function normalize(v)
    local d = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
    if d == 0 then return nil end
    return { v[1] / d, v[2] / d, v[3] / d }
end

--[[
| i  j  k|
|ix iy iz|
|jx jy jz|
--]]
function crossProduct(i, j)
    local x = i[2] * j[3] - i[3] * j[2]
    local y = i[3] * j[1] - i[1] * j[3]
    local z = i[1] * j[2] - i[2] * j[1]
    return { x, y, z }
end

-- create a camera to world matrix
-- use mtx:inverse() to get the world to camera matrix
function lookAt(eye, target, up)
    local globalUp = up and normalize(up) or { 0, 1, 0 }
    local forward = normalize({ eye[1] - target[1], eye[2] - target[2], eye[3] - target[3] })
    local right = crossProduct(globalUp, forward)
    local up = crossProduct(forward, right)
    return (mat({
        { right[1], right[2], right[3], 0 },
        { up[1], up[2], up[3], 0 },
        { forward[1], forward[2], forward[3], 0 },
        { eye[1], eye[2], eye[3], 1 }
    }) ^ 'T')
end

-- convert normalized device coordinates to canvas space
function NDCToCanvas(p, width, height)
    if p[1] < -1 or p[2] < -1 or p[3] < -1 or p[1] > 1 or p[2] > 1 or p[3] > 1 then
        return nil
    end
    local x = (p[1] + 1) / 2 * width
    local y = (1 - p[2]) / 2 * height
    local z = p[3]
    return { x, y, z }
end

function createSenceFromModel(model)
    local triangles = {}
    local vertex = model.vertex
    local uvs = model.uvs
    for _, f in ipairs(model.faces) do
        local c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
        local p0 = vertex[f[1][1]]
        local p1 = vertex[f[2][1]]
        local p2 = vertex[f[3][1]]
        local uv0 = uvs[f[1][2]]
        local uv1 = uvs[f[2][2]]
        local uv2 = uvs[f[3][2]]
        table.insert(triangles, { p0, p1, p2, c, uv0, uv1, uv2 })
    end
    return triangles
end

function createDebugSence1()
    local triangles = {}
    local c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
    table.insert(triangles, { { 0, 0, 0 }, { 0, 0, 5 }, { 5, 0, 0 }, c, { 0, 1 }, { 0, 0 }, { 1, 1 } })
    table.insert(triangles, { { 0, 0, 5 }, { 5, 0, 5 }, { 5, 0, 0 }, c, { 0, 0 }, { 1, 0 }, { 1, 1 } })
    c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
    table.insert(triangles, { { 0, 0, 0 }, { 5, 0, 0 }, { 5, 5, 0 }, c })
    table.insert(triangles, { { 5, 5, 0 }, { 0, 5, 0 }, { 0, 0, 0 }, c })
    return triangles
end

function createDebugSence2()
    local triangles = {}
    math.randomseed(0)
    for i = 1, 100 do
        local c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
        local p0 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
        local p1 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
        local p2 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
        table.insert(triangles, { p0, p1, p2, c })
    end
    return triangles
end

function drawPoint(buffer, p, c)
    local x = math.floor(p[1])
    local y = math.floor(p[2])
    buffer[x + y * width] = c
end

function getBoundingBox(p0, p1, p2, width, height)
    local t, r, b, l
    t = math.floor(math.max(0, math.min(p0[2], p1[2], p2[2])))
    r = math.floor(math.min(math.max(p0[1], p1[1], p2[1]), width - 1))
    b = math.floor(math.min(math.max(p0[2], p1[2], p2[2]), height - 1))
    l = math.floor(math.max(0, math.min(p0[1], p1[1], p2[1])))
    return { t, r, b, l }
end
