return function(spr, inputs)
    -- merge layers, this will be undo later
    app.command.FlattenLayers({ visibleOnly = true })
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
    local palette = spr.palettes[1]
    local paletteIdxes = {}
    for i = 0, #palette - 1 do
        if i ~= alpha then
            local c = palette:getColor(i)
            local idx = RGBToPaletteIdx({ c.red, c.green, c.blue })
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
    push(data, getTypeFromInputs(inputs))
    -- 0x 6A - 0x 6B (  2) = Unknown D (seems to always be 0x0000)
    push(data, 0, 0)
    -- 0x 6C - 0x26B (512) = Pattern Data 1 (mandatory)
    -- 0x26C - 0x46B (512) = Pattern Data 2 (optional)
    -- 0x46C - 0x66B (512) = Pattern Data 3 (optional)
    -- 0x66C - 0x86B (512) = Pattern Data 4 (optional)
    -- 0x86C - 0x86F (  4) = Zero padding (optional)
    --
    if spr.width == 32 then
        push(data, getDataBlock(pixels, spr.width, 0, 0, 32, 32)) -- full
    else
        push(data, getDataBlock(pixels, spr.width, 32, 0, 32, 32)) -- front up
        push(data, getDataBlock(pixels, spr.width, 0, 0, 32, 32)) -- back up
        push(data, getDataBlock(pixels, spr.width, 0, 48, 32, 16)) -- right sleeve
        push(data, getDataBlock(pixels, spr.width, 32, 48, 32, 16)) -- left sleeve
        push(data, getDataBlock(pixels, spr.width, 32, 32, 32, 16)) -- front bottom
        push(data, getDataBlock(pixels, spr.width, 0, 32, 32, 16)) -- back bottom
    end

    local dataLen = #data
    if dataLen > 620 and dataLen < 2160 then
        push(data, padding(2160 - dataLen))
    end

    -- qr encode
    local bitstr = ""
    for i, v in ipairs(data) do
        bitstr = bitstr .. string.char(v)
    end

    local qrcodes = {}
    if spr.width == 32 then
        table.insert(qrcodes, getQRcodeMatrix(bitstr))
    else
        local id = math.random(0, 255)
        table.insert(qrcodes, getQRcodeMatrix(string.sub(bitstr, 1, 540), { 0, 3, id, type = 11 }))
        table.insert(qrcodes, getQRcodeMatrix(string.sub(bitstr, 541, 1080), { 1, 3, id, type = 11 }))
        table.insert(qrcodes, getQRcodeMatrix(string.sub(bitstr, 1081, 1620), { 2, 3, id, type = 11 }))
        table.insert(qrcodes, getQRcodeMatrix(string.sub(bitstr, 1621, 2160), { 3, 3, id, type = 11 }))
    end

    -- create qrcode sprite
    local numOfQRCodes = #qrcodes
    local qrPadding = 2
    local qrWidth = #qrcodes[1]
    local qrSqrWidth = qrWidth + qrPadding * 2
    local qrSqrHeight = qrWidth * numOfQRCodes + qrPadding * (numOfQRCodes + 1)
    local qrSpr = Sprite(qrSqrWidth, qrSqrHeight, ColorMode.RGB)
    local qrPalette = qrSpr.palettes[1]
    qrPalette:resize(1) -- clear the palette
    local qrCel = app.activeCel
    local qrImg = qrCel.image
    local black = Color({ r = 0, g = 0, b = 0, a = 255 })
    local white = Color({ r = 255, g = 255, b = 255, a = 255 })
    local red = Color({ r = 255, g = 0, b = 0, a = 255 })
    qrImg:clear(white)

    -- render the qrcode
    for q = 1, numOfQRCodes do
        local offsetX = qrPadding
        local offsetY = qrPadding
        offsetY = offsetY + (qrWidth + qrPadding) * (q - 1)
        local qrcode = qrcodes[q]
        for r = 1, qrWidth do
            for c = 1, qrWidth do
                local color = red
                local v = qrcode[c][r]
                if v < 0 then
                    color = white
                elseif v > 0 then
                    color = black
                end

                qrImg:drawPixel(offsetX + c - 1, offsetY + r - 1, color)
            end
        end
    end

    -- done
    app.refresh()
end