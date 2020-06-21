--
-- Animal Crossing QRCode Generator for Aseprite
--
-- Version: 0.2.1
-- Author: Lingjia Liu <gmutoo@gmail.com>
-- Homepage: https://github.com/mutoo/aseprite-animalcrossing-qrcode-gen
-- License: MIT
--

dofile("./lib/palettes.lua")
dofile("./lib/helper.lua")

local generator = dofile("./lib/generator.lua")
local previewer = dofile("./lib/previewer.lua")

local supportedVersion = "1.2.18"
if app.version < Version(supportedVersion) then
    return app.alert("Upgrade to " .. supportedVersion .. " or later to use this plugin")
end

-- try to load settings file for user data
local settings = {}
pcall(function()
    settings = dofile('./settings.lua')
end)

-- load active sprite
local spr = app.activeSprite
if not spr then
    return app.alert("No active sprite")
end

-- load active cel
local cel = app.activeCel
if not cel then
    return app.alert("No active cel or content in current sprite")
end

local isIndexMode = spr.colorMode == ColorMode.INDEXED
local palette = spr.palettes[1]
local isBasicDesign = spr.width == 32 and spr.height == 32
local isProDesign = spr.width == 64 and spr.height == 64
local isSupportedDesign = isBasicDesign or isProDesign
local isSuitablePalette = #palette <= 16

local dlg = Dialog("Animal Crossing QRCode Generator")

dlg:separator({ text = "Check List" })

dlg:check({
    id = "size",
    label = "Sprite Size",
    text = "is 32x32 or 64x64",
    selected = isSupportedDesign
})

dlg:modify({ id = "size", enabled = false })

dlg:check({
    id = "colorMode",
    label = "Color Mode",
    text = "is Indexed",
    selected = isIndexMode
})

dlg:modify({ id = "colorMode", enabled = false })

dlg:check({
    id = "sizeOfPalette",
    label = "Palette Size",
    text = "is NOT greater than 16",
    selected = isSuitablePalette
})

dlg:modify({ id = "sizeOfPalette", enabled = false })

dlg:separator({ text = "Metas" })

dlg:entry({
    id = "title",
    label = "Title",
    text = settings.title or "Untitled"
})
dlg:entry({
    id = "author",
    label = "Author",
    text = settings.author or "Unknown"
})
dlg:entry({
    id = "town",
    label = "Town",
    text = settings.town or "Aseprite"
})

dlg:separator({ text = "Type" })

if spr.width == 32 then
    dlg:radio({
        id = 'paint',
        label = 'Basic',
        text = 'Paint',
        selected = true
    })
    dlg:radio({
        id = 'cap',
        text = 'Knit Cap'
    })
    dlg:radio({
        id = 'hornedHat',
        text = 'Horned Hat'
    })
else
    dlg:radio({ id = 'shirt', label = 'Pro', text = 'Shirt', selected = true })
    dlg:radio({ id = 'dress', text = 'Dress' })
    dlg:radio({ id = 'sleeveless', label = 'Sleeves', text = 'None', selected = true })
    dlg:radio({ id = 'short', text = 'Short' })
    dlg:radio({ id = 'long', text = 'Long' })
end

dlg:separator({ text = "Action" })

if isProDesign then
    dlg:button({
        id = "previewBtn",
        text = "&Preview",
        onclick = function()
            dlg:close()
            previewer(spr, dlg.data)
        end
    })

    dlg:modify({
        id = "previewBtn",
        enabled = isIndexMode and isSuitablePalette
    })
end

dlg:button({
    id = "generateBtn",
    text = "&Generate"
})

dlg:modify({
    id = "generateBtn",
    enabled = isIndexMode and isSuitablePalette and isSupportedDesign
})

dlg:show()

local inputs = dlg.data
if inputs.generateBtn then
    generator(spr, inputs)
end
