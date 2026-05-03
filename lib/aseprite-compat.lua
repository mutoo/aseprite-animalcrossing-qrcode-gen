local M = {}

local function appApiVersion()
    return app.apiVersion or 0
end

function M.isApiVersionAtLeast(apiVersion)
    return appApiVersion() >= apiVersion
end

function M.alert(message)
    if app.isUIAvailable ~= false and app.alert then
        return app.alert(message)
    end
    print(message)
end

function M.refresh()
    if app.refresh then
        pcall(app.refresh)
    end
end

function M.getActiveSprite()
    return app.sprite or app.activeSprite
end

function M.setActiveSprite(sprite)
    local ok = pcall(function()
        app.sprite = sprite
    end)
    if not ok then
        app.activeSprite = sprite
    end
end

function M.getActiveCel()
    return app.cel or app.activeCel
end

function M.getActiveFrame()
    return app.frame or app.activeFrame
end

function M.getActiveFrameNumber()
    local frame = M.getActiveFrame()
    if type(frame) == "number" then
        return frame
    end
    if frame and frame.frameNumber then
        return frame.frameNumber
    end
    return 1
end

function M.setActiveFrame(frame)
    local ok = pcall(function()
        app.frame = frame
    end)
    if not ok then
        pcall(function()
            app.activeFrame = frame
        end)
    end
end

function M.getSpritePalette(sprite, frameNumber)
    local palettes = sprite and sprite.palettes
    if not palettes or #palettes == 0 then
        return nil
    end

    local palette = palettes[1]
    if not frameNumber then
        return palette
    end

    for i = 1, #palettes do
        local candidate = palettes[i]
        local candidateFrame = candidate.frame
        local candidateFrameNumber = 1
        if type(candidateFrame) == "number" then
            candidateFrameNumber = candidateFrame
        elseif candidateFrame and candidateFrame.frameNumber then
            candidateFrameNumber = candidateFrame.frameNumber
        end
        if candidateFrameNumber <= frameNumber then
            palette = candidate
        end
    end

    return palette
end

function M.flattenVisibleLayers()
    local args = {
        visibleOnly = true
    }
    if M.isApiVersionAtLeast(36) then
        args.ui = false
    end
    app.command.FlattenLayers(args)
end

_G.asepriteCompat = M

return M
