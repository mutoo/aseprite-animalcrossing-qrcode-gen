local source = debug.getinfo(1, "S").source
local scriptPath = string.sub(source, 1, 1) == "@" and string.sub(source, 2) or source
local rootDir = string.match(scriptPath, "^(.*[/\\])tests[/\\][^/\\]+$") or "./"

function script_dofile(path)
    return dofile(rootDir .. path)
end

local compat = script_dofile("lib/aseprite-compat.lua")
script_dofile("lib/palettes.lua")
script_dofile("lib/helper.lua")

local generator = script_dofile("lib/generator.lua")
local previewer = script_dofile("lib/previewer.lua")
local outputDir = app.params and app.params.outputDir or nil

local function outputPath(filename)
    if not outputDir or outputDir == "" then
        return nil
    end
    return outputDir .. "/" .. filename
end

local function saveSprite(sprite, filename)
    local path = outputPath(filename)
    if path then
        sprite:saveCopyAs(path)
        print("saved: " .. path)
    end
end

local function assertTrue(value, message)
    if not value then
        error(message, 2)
    end
end

local function makePalette()
    local palette = Palette(16)
    palette:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
    for i = 1, 15 do
        palette:setColor(i, Color {
            r = (i * 37) % 256,
            g = (i * 73) % 256,
            b = (i * 109) % 256,
            a = 255
        })
    end
    return palette
end

local function makeIndexedSprite(width, height)
    local sprite = Sprite(width, height, ColorMode.INDEXED)
    sprite:setPalette(makePalette())
    sprite.transparentColor = 0

    local image = sprite.cels[1].image
    for pixel in image:pixels() do
        pixel((pixel.x + pixel.y) % 15 + 1)
    end

    return sprite
end

local function countNonWhitePixels(image)
    local white = Color { r = 255, g = 255, b = 255, a = 255 }.rgbaPixel
    local count = 0
    for pixel in image:pixels() do
        if pixel() ~= white then
            count = count + 1
        end
    end
    return count
end

local basic = makeIndexedSprite(32, 32)
saveSprite(basic, "basic-source.png")
compat.setActiveSprite(basic)
compat.setActiveFrame(1)
generator(basic, {
    title = "Smoke",
    author = "Codex",
    town = "Aseprite",
    paint = true
})

local basicQr = compat.getActiveSprite()
assertTrue(basicQr ~= basic, "32x32 generation did not create a new sprite")
assertTrue(basicQr.colorMode == ColorMode.RGB, "32x32 QR sprite should be RGB")
assertTrue(basicQr.width > 0 and basicQr.height > 0, "32x32 QR sprite has invalid bounds")
print(string.format("basic QR: %dx%d", basicQr.width, basicQr.height))
saveSprite(basicQr, "basic-qrcode.png")
basicQr:close()
basic:close()

local pro = makeIndexedSprite(64, 64)
saveSprite(pro, "pro-source.png")
compat.setActiveSprite(pro)
compat.setActiveFrame(1)

local preview = previewer(pro, {
    shirt = true,
    sleeveless = true
})
assertTrue(preview.width == 256 and preview.height == 256, "preview sprite has invalid bounds")
assertTrue(countNonWhitePixels(preview.cels[1].image) > 0, "preview sprite rendered blank")
print(string.format("preview: %dx%d", preview.width, preview.height))
saveSprite(preview, "pro-preview.png")
preview:close()

compat.setActiveSprite(pro)
compat.setActiveFrame(1)
generator(pro, {
    title = "Smoke Pro",
    author = "Codex",
    town = "Aseprite",
    shirt = true,
    sleeveless = true
})

local proQr = compat.getActiveSprite()
assertTrue(proQr ~= pro, "64x64 generation did not create a new sprite")
assertTrue(proQr.colorMode == ColorMode.RGB, "64x64 QR sprite should be RGB")
assertTrue(proQr.height > proQr.width, "64x64 QR sprite should contain stacked QR codes")
print(string.format("pro QR: %dx%d", proQr.width, proQr.height))
saveSprite(proQr, "pro-qrcode.png")
proQr:close()
pro:close()

print("Aseprite 1.3 smoke test passed")
