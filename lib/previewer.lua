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
    local mtx = perspectiveMat * worldToCamMat * modelMat
    local frameBuffer = createBuffer(size, nil)
    local zBuffer = createBuffer(size, f)
    for t, triangle in ipairs(triangles) do
        local t0, t1, t2, c, uv0, uv1, uv2 = table.unpack(triangle)
        local p0 = NDCToCanvas(transform(mtx, t0), width, height)
        local p1 = NDCToCanvas(transform(mtx, t1), width, height)
        local p2 = NDCToCanvas(transform(mtx, t2), width, height)
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
                                local uv = uvTex:getPixel(u * uvTex.width, (1 - v) * uvTex.height)
                                local t = Color(uv)
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
