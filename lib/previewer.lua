-- right-handed system
--  right: x
--  up: y
--  forward: -z
-- w/ column-major matrix

local width = 256
local height = 256
local size = width * height

local black = Color { r = 0, g = 0, b = 0, a = 255 }
local white = Color { r = 255, g = 255, b = 255, a = 255 }
local skin = Color { r = 217, g = 160, b = 102, a = 255 }

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

local perspectiveMat = perspective(n, f, t, b, r, l)

local triangles = {}
local modelRotateY = 0
local uvTex = Image({ width = 64, height = 64 })

function draw(image)
    local modelMat = rotateY(modelRotateY)
    local viewMat = worldToCamMat * modelMat
    local projMtx = perspectiveMat * viewMat
    local frameBuffer = createBuffer(size, nil)
    local zBuffer = createBuffer(size, f)
    for t, triangle in ipairs(triangles) do
        local p0, p1, p2, c, uv0, uv1, uv2, n0, n1, n2 = table.unpack(triangle)
        p0 = NDCToCanvas(transform(projMtx, p0), width, height)
        p1 = NDCToCanvas(transform(projMtx, p1), width, height)
        p2 = NDCToCanvas(transform(projMtx, p2), width, height)
        n0 = transform(viewMat, n0, 0)
        n1 = transform(viewMat, n1, 0)
        n2 = transform(viewMat, n2, 0)
        if p0 and p1 and p2 then
            local area = edge(p0, p1, p2)
            local bbox = getBoundingBox(p0, p1, p2, width, height)
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
                    if frontInside or backInside then
                        w0 = w0 / area / p0[3]
                        w1 = w1 / area / p1[3]
                        w2 = w2 / area / p2[3]
                        local z = 1 / (w0 + w1 + w2);
                        local idx = row * width + col
                        if z < zBuffer[idx] then
                            zBuffer[idx] = z
                            if uv0 and uv1 and uv2 then
                                local u = (uv0[1] * w0 + uv1[1] * w1 + uv2[1] * w2) * z;
                                local v = (uv0[2] * w0 + uv1[2] * w1 + uv2[2] * w2) * z;
                                local uv = uvTex:getPixel(u * uvTex.width, (1 - v) * uvTex.height)
                                local nx = (n0[1] * w0 + n1[1] * w1 + n2[1] * w2) * z;
                                local ny = (n0[2] * w0 + n1[2] * w1 + n2[2] * w2) * z;
                                local nz = (n0[3] * w0 + n1[3] * w1 + n2[3] * w2) * z;
                                local n = normalize({ nx, ny, nz })
                                local d = math.max(0, dotProduct(n, { 0, 0, 1 }))
                                d = math.ceil(math.sqrt(d) * 3) / 3
                                c = Color(uv)
                                c.red = c.red * d
                                c.green = c.green * d
                                c.blue = c.blue * d
                                --                                c = Color({ gray = d * 255 })
                                frameBuffer[idx] = frontInside and c.rgbaPixel or black.rgbaPixel
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
        local idx = it.y * image.width + it.x
        --        local z = zBuffer[idx]
        --        local gray = Color({ gray = z / f * 255, alpha = 255 })
        --        it(gray.rgbaPixel)
        it(frameBuffer[idx] or white.rgbaPixel)
    end

    app.refresh()
end

local models = {
    [0] = 'dress-long-sleeve',
    'dress-half-sleeve',
    'dress-no-sleeve',
    'shirt-long-sleeve',
    'shirt-half-sleeve',
    'shirt-no-sleeve',
}

function reloadUV(spr, renderSpr)
    local current = app.activeSprite
    uvTex:drawSprite(spr)
    app.activeSprite = renderSpr
    app.refresh()
end

return function(spr, inputs)
    local type = getTypeFromInputs(inputs)

    -- load model
    local model = dofile('./models/' .. models[type] .. '.lua')
    triangles = createSenceFromModel(model)

    local renderSpr = Sprite(width, height, ColorMode.RGB)
    renderSpr:setPalette(spr.palettes[1])
    local renderCel = renderSpr.cels[1]
    local renderImage = renderCel.image

    local rotateAndDraw = function(angle)
        return function()
            modelRotateY = modelRotateY + angle
            draw(renderImage)
        end
    end

    local dlg = Dialog({
        title = "Animal Crossing Design Preview",
        onclose = function()
            renderSpr:close()
        end
    })
    dlg:button {
        text = "<<",
        onclick = rotateAndDraw(-math.pi / 4)
    }
    dlg:button {
        text = "<",
        onclick = rotateAndDraw(-math.pi / 8)
    }
    dlg:button {
        text = ">",
        onclick = rotateAndDraw(math.pi / 8)
    }
    dlg:button {
        text = ">>",
        onclick = rotateAndDraw(math.pi / 4)
    }
    dlg:button {
        text = "Reload UV",
        onclick = function()
            reloadUV(spr, renderSpr)
            draw(renderImage)
        end
    }
    dlg:button {
        text = "Close",
        onclick = function()
            dlg:close()
        end
    }
    dlg:show({ wait = false })
    reloadUV(spr, renderSpr)
    draw(renderImage)
end
