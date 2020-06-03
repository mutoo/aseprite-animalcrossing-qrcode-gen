local qrencode = dofile("./qrencode.lua")

-- insert multi values into table
function push(t, ...)
    for i, v in ipairs({...}) do
        table.insert(t, v)
    end
end

-- pad with zero
function padding(n, ...)
    local args = {...}
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
    local str = {...}
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
