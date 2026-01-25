local addonName, ns = ...

function ns.SetupOptions()
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.name = addonName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName)

    local subText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subText:SetText("Press Enter to save changes.")

    -- Configuration Inputs (Left Side)
    local sizeInput = ns.Libs.CreateNumberInput(panel, "Icon Size (px)", "iconSize", function(val)
        if ns.frame then ns.frame:SetSize(val, val) end
    end)
    sizeInput:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 10, -30)

    local xInput = ns.Libs.CreateNumberInput(panel, "Position X", "posX", function() ns.ApplySettings() end)
    xInput:SetPoint("TOPLEFT", sizeInput, "BOTTOMLEFT", 0, -20)

    local yInput = ns.Libs.CreateNumberInput(panel, "Position Y", "posY", function() ns.ApplySettings() end)
    yInput:SetPoint("TOPLEFT", xInput, "BOTTOMLEFT", 0, -20)

    local fadeInput = ns.Libs.CreateNumberInput(panel, "Fade Duration (sec)", "fadeDuration", function(val)
        if ns.frame then ns.frame.alphaAnim:SetDuration(val) end
    end)
    fadeInput:SetPoint("TOPLEFT", yInput, "BOTTOMLEFT", 0, -20)

    local delayInput = ns.Libs.CreateNumberInput(panel, "Fade Start Delay (sec)", "fadeDelay", function(val)
        if ns.frame then ns.frame.alphaAnim:SetStartDelay(val) end
    end)
    delayInput:SetPoint("TOPLEFT", fadeInput, "BOTTOMLEFT", 0, -20)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(120, 25)
    testBtn:SetText("Test Flash")
    testBtn:SetPoint("TOPLEFT", delayInput, "BOTTOMLEFT", 0, -30)
    testBtn:SetScript("OnClick", function() ns.TestFlash() end)

    -- Blacklist Panel (Right Side)
    local blacklistPanel = ns.Libs.CreateBlacklistPanel(panel)
    blacklistPanel:SetPoint("TOPRIGHT", -20, -20)
    blacklistPanel:SetPoint("BOTTOMRIGHT", -20, 20)

    -- Register Category
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    ns.CategoryID = category:GetID()
end
