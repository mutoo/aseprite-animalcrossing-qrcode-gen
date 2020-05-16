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
