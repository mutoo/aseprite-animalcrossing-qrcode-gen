--
-- Animal Crossing QRCode Generator for Aseprite
--
-- Version: 0.1.1
-- Author: Lingjia Liu <gmutoo@gmail.com>
-- Homepage: https://github.com/mutoo/aseprite-animalcrossing-qrcode-gen
-- License: MIT
--

dofile("./lib/palettes.lua")
dofile("./lib/helper.lua")
local qrencode = dofile("./lib/qrencode.lua")

-- try to load settings file for user data
local settings = {}
pcall(function ()
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
local isRightSize = spr.width == 32 and spr.height == 32
local isSuitablePalette = #palette <= 16

local dlg = Dialog("Animal Crossing QRCode Generator")

dlg:separator({text = "Check List"})

dlg:check(
    {
        id = "size",
        label = "Sprite Size",
        text = "is 32x32",
        selected = isRightSize
    }
)

dlg:modify(
    {
        id = "size",
        enabled = false
    }
)

dlg:check(
    {
        id = "colorMode",
        label = "Color Mode",
        text = "is Indexed",
        selected = isIndexMode
    }
)

dlg:modify(
    {
        id = "colorMode",
        enabled = false
    }
)

dlg:check(
    {
        id = "sizeOfPalette",
        label = "Palette Size",
        text = "is NOT greater than 16",
        selected = isSuitablePalette
    }
)

dlg:modify(
    {
        id = "sizeOfPalette",
        enabled = false
    }
)

dlg:separator({text = "Metas"})

dlg:entry({id = "title", label = "Title", text = settings.title or "Untitled"})
dlg:entry({id = "author", label = "Author", text = settings.author or "Unknown"})
dlg:entry({id = "town", label = "Town", text = settings.town or "Aseprite"})

dlg:radio({ id = 'paint', label = 'Type', text = 'Paint', selected = true})
dlg:radio({ id = 'cap', text = 'Knit Cap'})
dlg:radio({ id = 'hornedHat', text = 'Horned Hat'})

dlg:separator({text = "Action"})

dlg:button(
    {
        id = "generateBtn",
        text = "&Generate"
    }
)

dlg:modify(
    {
        id = "generateBtn",
        enabled = isIndexMode and isRightSize and isSuitablePalette
    }
)

dlg:show()

local inputs = dlg.data
if inputs.generateBtn then
    -- merge layers, this will be undo later
    app.command.FlattenLayers({visibleOnly = true})
    -- analytic image
    local cel = app.activeCel
    local img = cel.image
    local pos = cel.position
    local pixels = {}
    local alpha = spr.transparentColor
    local w = spr.width
    local h = spr.height
    local c = w * h - 1
    -- reset the pixels array
    for i = 0, c do
        pixels[i] = 0x0f
    end
    -- update pixels array with image data
    for p in img:pixels() do
        local c = p()
        local i = (pos.y + p.y) * w + (pos.x + p.x)
        pixels[i] = shiftWithAlpha(c, alpha)
    end
    -- revert the flatten action
    app.undo()

    -- compose qr data
    local data = {}
    -- ACNL data layout.
    --
    -- QR codes are blocks of 540 bytes each, providing this data in sequence:
    --
    -- 0x 00 - 0x 29 ( 42) = Pattern Title
    push(data, padding(42, utf16(inputs.title:byte(1, 20))))
    -- 0x 2A - 0x 2B (  2) = User ID
    push(data, 173, 222) -- 0xdead
    -- -- 0x 2C - 0x 3F ( 20) = User Name
    push(data, padding(20, utf16(inputs.author:byte(1, 9))))
    -- -- 0x 40 - 0x 41 (  2) = Town ID
    push(data, 239, 190) -- 0xbeef
    -- -- 0x 42 - 0x 55 ( 20) = Town Name
    push(data, padding(20, utf16(inputs.town:byte(1, 9))))
    -- -- 0x 56 - 0x 57 (  2) = Unknown A (values are usually random - changing seems to have no effect)
    push(data, 25, 49) -- 0x3119
    -- -- 0x 58 - 0x 66 ( 15) = Color code indexes
    local paletteIdxes = {}
    for i = 0, #palette - 1 do
        if i ~= alpha then
            local c = palette:getColor(i)
            local idx = RGBToPaletteIdx({c.red, c.green, c.blue})
            table.insert(paletteIdxes, idx - 1)
        end
    end
    push(data, padding(15, table.unpack(paletteIdxes)))
    -- 0x 67         (  1) = Unknown B (value is usually random - changing seems to have no effect)
    push(data, 204) -- 0xcc
    -- 0x 68         (  1) = Unknown C (seems to always be 0x0A or 0x00)
    push(data, 10) -- 0x0a
    -- 0x 69         (  1) = Pattern type (see below)
    --  Pattern types:
    --  0x00 = Fullsleeve dress (pro)
    --  0x01 = Halfsleeve dress (pro)
    --  0x02 = Sleeveless dress (pro)
    --  0x03 = Fullsleeve shirt (pro)
    --  0x04 = Halfsleeve shirt (pro)
    --  0x05 = Sleeveless shirt (pro)
    --  0x06 = Horned Hat
    --  0x07 = Knit Cap
    --  0x08 = Standee (pro)
    --  0x09 = Plain pattern (easel)
    -- currently we only support the 32x32 type
    if inputs.paint then
        push(data, 9) -- Plain pattern (easel)
    end
    if inputs.cap then
        push(data, 7) -- Knit Cap
    end
    if inputs.hornedHat then
        push(data, 6) -- Horned Hat
    end
    -- 0x 6A - 0x 6B (  2) = Unknown D (seems to always be 0x0000)
    push(data, 0, 0)
    -- 0x 6C - 0x26B (512) = Pattern Data 1 (mandatory)
    -- 0x26C - 0x46B (512) = Pattern Data 2 (optional)
    -- 0x46C - 0x66B (512) = Pattern Data 3 (optional)
    -- 0x66C - 0x86B (512) = Pattern Data 4 (optional)
    -- 0x86C - 0x86F (  4) = Zero padding (optional)
    --
    for i = 0, c, 2 do
        push(data, pixels[i] + pixels[i + 1] * 16)
    end

    -- qr encode
    local bitstr = ""
    for i, v in ipairs(data) do
        bitstr = bitstr .. string.char(v)
    end
    local ok, ret = qrencode.qrcode(bitstr, 2)
    if not ok then
        return app.alert(ret)
    end

    -- create qrcode sprite
    local qrPadding = 1
    local qrWidth = #ret
    local qrSpr = Sprite(qrWidth + 2, qrWidth + 2, ColorMode.RGB)
    local qrPalette = qrSpr.palettes[1]
    qrPalette:resize(1) -- clear the palette
    local qrCel = app.activeCel
    local qrImg = qrCel.image
    local black = Color({r = 0, g = 0, b = 0, a = 255})
    local white = Color({r = 255, g = 255, b = 255, a = 255})
    local red = Color({r = 255, g = 0, b = 0, a = 255})

    -- render the qrcode
    for r = 0, qrWidth + 1 do
        for c = 0, qrWidth + 1 do
            local color = red
            -- border
            if c == 0 or c == qrWidth + 1 or r == 0 or r == qrWidth + 1 then
                color = white
            else
                local v = ret[c][r]
                if v < 0 then
                    color = white
                elseif v > 0 then
                    color = black
                end
            end

            qrImg:drawPixel(c, r, color)
        end
    end

    -- done
    app.refresh()
end
