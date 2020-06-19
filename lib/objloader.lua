-- right-handed system
--  x  - right
--  y  - up
--  -z - forward
--
-- w/ column-major matrix

local mat = dofile('./matrix.lua')
local model = dofile('../models/dress-half-sleeve.lua')
local vertex = model.vertex
local uvs = model.uvs
local angleY = 0

local image = app and app.activeCel.image or { width = 256, height = 256 }
local black = Color { r = 0, g = 0, b = 0, a = 255 }
local white = Color { r = 255, g = 255, b = 255, a = 255 }
local skin = Color { r = 217, g = 160, b = 102, a = 255 }

local width = image.width
local height = image.height
local size = width * height

-- check if p2 on the right side of line p0p1
-- p0, p1, p2 in counter-clock order
function edge(p0, p1, p2)
    return (p1[1] - p0[1]) * (p2[2] - p0[2]) - (p2[1] - p0[1]) * (p1[2] - p0[2])
end

function createBuffer(size, fill)
    local buffer = {}
    for i = 0, size - 1 do
        buffer[i] = fill
    end
    return buffer
end

function rotateZ(a)
    return mat({
        { math.cos(a), -math.sin(a), 0, 0 },
        { math.sin(a), math.cos(a), 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 },
    })
end

function rotateX(a)
    return mat({
        { 1, 0, 0, 0 },
        { 0, math.cos(a), -math.sin(a), 0 },
        { 0, math.sin(a), math.cos(a), 0 },
        { 0, 0, 0, 1 },
    })
end

function rotateY(a)
    return mat({
        { math.cos(a), 0, math.sin(a), 0 },
        { 0, 1, 0, 0 },
        { -math.sin(a), 0, math.cos(a), 0 },
        { 0, 0, 0, 1 },
    })
end

function transform(matrix, vec)
    local vecMat = mat({ vec[1], vec[2], vec[3], 1 })
    local transformed = matrix * vecMat
    local w = transformed[4][1]
    return { transformed[1][1] / w, transformed[2][1] / w, transformed[3][1] / w }
end

local IDMat = mat(4, 'I')
local modelMat = IDMat

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

--local camToWorldMat = lookAt({ 10, 10, 10 }, { 0, 0, 0 }, { 0, 1, 0 });
local camToWorldMat = lookAt({ 5, 8, 5 }, { 0, 4, 0 }, { 0, 1, 0 });
local worldToCamMat = camToWorldMat:invert()

local fov = 60
local n = 0.1
local f = 20
local imageAspectRatio = width / height
local scale = math.tan(fov * 0.5 * math.pi / 180) * n;
local r = imageAspectRatio * scale
local l = -r;
local t = scale
local b = -t

local perspectiveMat = mat({
    { 2 * n / (r - l), 0, (r + l) / (r - l), 0 },
    { 0, 2 * n / (t - b), (t + b) / (t - b), 0 },
    { 0, 0, -(f + n) / (f - n), -(2 * f) / (f - n) },
    { 0, 0, -1, 0 },
})

function NDCToCanvas(p)
    if p[1] < -1 or p[2] < -1 or p[3] < -1 or p[1] > 1 or p[2] > 1 or p[3] > 1 then
        return nil
    end
    local x = (p[1] + 1) / 2 * width
    local y = (1-p[2]) / 2 * height
    local z = p[3]
    return { x, y, z }
end

local triangles = {}

--local c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
--table.insert(triangles, { { 0, 0, 0 }, { 0, 0, 5 }, { 5, 0, 0 }, c, { 0, 1 }, { 0, 0 }, { 1, 1 } })
--table.insert(triangles, { { 0, 0, 5 }, { 5, 0, 5 }, { 5, 0, 0 }, c, { 0, 0 }, { 1, 0 }, { 1, 1 } })
--c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
--table.insert(triangles, { { 0, 0, 0 }, { 5, 0, 0 }, { 5, 5, 0 }, c })
--table.insert(triangles, { { 5, 5, 0 }, { 0, 5, 0 }, { 0, 0, 0 }, c })

--math.randomseed(0)
--for i = 1, 100 do
--    local c = Color { r = math.random(0, 255), g = math.random(0, 255), b = math.random(0, 255), a = 255 }
--    local p0 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
--    local p1 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
--    local p2 = { math.random(-5, 5), -math.random(-5, 5), math.random(-5, 5) }
--    table.insert(triangles, { p0, p1, p2, c})
--end

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

function drawPoint(buffer, p, c)
    local x = math.floor(p[1])
    local y = math.floor(p[2])
    buffer[x + y * width] = c
end

function getBoundingBox(p0, p1, p2)
    local t, r, b, l
    t = math.floor(math.max(0, math.min(p0[2], p1[2], p2[2])))
    r = math.floor(math.min(math.max(p0[1], p1[1], p2[1]), width - 1))
    b = math.floor(math.min(math.max(p0[2], p1[2], p2[2]), height - 1))
    l = math.floor(math.max(0, math.min(p0[1], p1[1], p2[1])))
    return { t, r, b, l }
end

function draw()
    modelMat = rotateY(angleY)
    local mtx = perspectiveMat * worldToCamMat * modelMat
    local frameBuffer = createBuffer(size, nil)
    local zBuffer = createBuffer(size, f)

    for t, triangle in ipairs(triangles) do
        local t0, t1, t2, c, uv0, uv1, uv2 = table.unpack(triangle)
        local p0 = NDCToCanvas(transform(mtx, t0))
        local p1 = NDCToCanvas(transform(mtx, t1))
        local p2 = NDCToCanvas(transform(mtx, t2))
        --        local p0, p1, p2 = table.unpack(triangle)
        --    print(table.unpack(p0))
        --    print(table.unpack(p1))
        --    print(table.unpack(p2))
        if p0 and p1 and p2 then
            local area = edge(p0, p1, p2)
            local bbox = getBoundingBox(p0, p1, p2)
            --                drawPoint(frameBuffer, p0, c)
            --                drawPoint(frameBuffer, p1, c)
            --                drawPoint(frameBuffer, p2, c)
            for row = bbox[1], bbox[3] do
                for col = bbox[4], bbox[2] do
                    local p = { col, row }
                    local w0 = edge(p1, p2, p)
                    local w1 = edge(p2, p0, p)
                    local w2 = edge(p0, p1, p)
                    -- the canvas coordinate is upside down
                    -- so the edge function is became left-handed
                    local frontInside = w0 <= 0 and w1 <= 0 and w2 <= 0
                    local backInside = w0 >= 0 and w1 >= 0 and w2 >= 0
                    if frontInside or backInside  then
                        w0 = w0 / area
                        w1 = w1 / area
                        w2 = w2 / area
                        local z = p0[3] * w0 + p1[3] * w1 + p2[3] * w2;
                        local idx = row * width + col
                        if z < zBuffer[idx] then
                            zBuffer[idx] = z
                            if uv0 and uv1 and uv2 then
                                local u = uv0[1] * w0 + uv1[1] * w1 + uv2[1] * w2;
                                local v = uv0[2] * w0 + uv1[2] * w1 + uv2[2] * w2;
                                local t = Color({ r = u * 255, g = v * 255, b = 255 })
                                frameBuffer[idx] = t.rgbaPixel
                            else
                                frameBuffer[idx] = frontInside and c.rgbaPixel or skin.rgbaPixel
                            end
                        end
                    end
                end
            end
        end
    end

    for it in image:pixels() do
        local c = it()
        it(frameBuffer[it.y * image.width + it.x] or white.rgbaPixel)
    end

    app.refresh()
end

draw()

local dlg = Dialog("Animal Crossing Design Preview")
dlg:button {
    text = "Left",
    onclick = function()
        angleY = angleY - math.pi / 16
        draw()
    end
}
dlg:button {
    text = "Right",
    onclick = function()
        angleY = angleY + math.pi / 16
        draw()
    end
}
dlg:button {
    text = "Close",
    onclick = function()
        dlg:close()
    end
}
dlg:show({ wait = false })