local _, ns = ...

local function CreateNumberInput(parent, label, key, updateFunc)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(60, 20)
    editbox:SetAutoFocus(false)

    local labelText = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("LEFT", editbox, "RIGHT", 10, 0)
    labelText:SetText(label)

    editbox:SetScript("OnShow", function(self)
        self:SetText(tostring(CooldownFlashDB[key] or ns.Defaults[key]))
        self:SetCursorPosition(0)
    end)

    editbox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then
            CooldownFlashDB[key] = val
            if updateFunc then updateFunc(val) end
            self:ClearFocus()
        else
            self:SetText(tostring(CooldownFlashDB[key]))
        end
    end)

    editbox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(CooldownFlashDB[key]))
        self:ClearFocus()
    end)

    return editbox
end

function ns.SetupOptions()
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.name = "CooldownFlash"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CooldownFlash Settings")

    local subText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subText:SetText("Press Enter to save changes.")

    local sizeInput = CreateNumberInput(panel, "Icon Size (px)", "iconSize", function(val)
        if ns.frame then ns.frame:SetSize(val, val) end
    end)
    sizeInput:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 10, -30)

    local xInput = CreateNumberInput(panel, "Position X", "posX", function() ns.ApplySettings() end)
    xInput:SetPoint("TOPLEFT", sizeInput, "BOTTOMLEFT", 0, -20)

    local yInput = CreateNumberInput(panel, "Position Y", "posY", function() ns.ApplySettings() end)
    yInput:SetPoint("TOPLEFT", xInput, "BOTTOMLEFT", 0, -20)

    local fadeInput = CreateNumberInput(panel, "Fade Duration (sec)", "fadeDuration", function(val)
        if ns.frame and ns.frame.alphaAnim then ns.frame.alphaAnim:SetDuration(val) end
    end)
    fadeInput:SetPoint("TOPLEFT", yInput, "BOTTOMLEFT", 0, -20)

    local delayInput = CreateNumberInput(panel, "Fade Start Delay (sec)", "fadeDelay", function(val)
        if ns.frame and ns.frame.alphaAnim then ns.frame.alphaAnim:SetStartDelay(val) end
    end)
    delayInput:SetPoint("TOPLEFT", fadeInput, "BOTTOMLEFT", 0, -20)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(120, 25)
    testBtn:SetText("Test Flash")
    testBtn:SetPoint("TOPLEFT", delayInput, "BOTTOMLEFT", 0, -30)

    testBtn:SetScript("OnClick", function() ns.TestFlash() end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "CooldownFlash")
    Settings.RegisterAddOnCategory(category)

    ns.CategoryID = category:GetID()
end
