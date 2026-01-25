local _, ns = ...
ns.Libs = {}

-- Creates a standard labeled numeric input box
function ns.Libs.CreateNumberInput(parent, label, key, updateFunc)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(60, 20)
    editbox:SetAutoFocus(false)

    local labelText = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("LEFT", editbox, "RIGHT", 10, 0)
    labelText:SetText(label)

    editbox:SetScript("OnShow", function(self)
        self:SetText(tostring(CooldownFlashDB[key] or ns.Config.Defaults[key]))
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

-- Creates the Blacklist Manager Panel
function ns.Libs.CreateBlacklistPanel(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(300, 400)
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    local title = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Ignored Spells")

    -- Add Input
    local addInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    addInput:SetSize(120, 20)
    addInput:SetPoint("TOPLEFT", 20, -45)
    addInput:SetAutoFocus(false)
    addInput:SetTextInsets(5, 5, 0, 0)

    local addLabel = addInput:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    addLabel:SetPoint("BOTTOMLEFT", addInput, "TOPLEFT", 0, 2)
    addLabel:SetText("Add Spell ID:")

    local addButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    addButton:SetSize(60, 22)
    addButton:SetPoint("LEFT", addInput, "RIGHT", 5, 0)
    addButton:SetText("Add")

    -- List ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(240, 1)
    scrollFrame:SetScrollChild(content)

    local function RefreshList()
        for _, child in ipairs({ content:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local spells = {}
        for id in pairs(CooldownFlashDB.ignoredSpells or {}) do
            local info = C_Spell.GetSpellInfo(id)
            table.insert(spells, {
                id = id,
                name = info and info.name or ("Unknown ID: " .. id),
                icon = info and info.iconID or 134400
            })
        end
        table.sort(spells, function(a, b) return a.name < b.name end)

        local lastRow
        for _, spell in ipairs(spells) do
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(240, 24)
            row:SetPoint("TOPLEFT", lastRow and lastRow or content, lastRow and "BOTTOMLEFT" or "TOPLEFT", 0, lastRow and -2 or 0)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", 2, 0)
            icon:SetTexture(spell.icon)

            local delBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            delBtn:SetSize(24, 24)
            delBtn:SetPoint("RIGHT", 0, 0)
            delBtn:SetScript("OnClick", function()
                CooldownFlashDB.ignoredSpells[spell.id] = nil
                RefreshList()
            end)

            local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            text:SetPoint("RIGHT", delBtn, "LEFT", -5, 0)
            text:SetJustifyH("LEFT")
            text:SetText(spell.name .. " |cff888888(" .. spell.id .. ")|r")

            lastRow = row
        end
        content:SetHeight(math.max(#spells * 26, 10))
    end

    local function AddSpell()
        local id = tonumber(addInput:GetText())
        if id and C_Spell.GetSpellInfo(id) then
            CooldownFlashDB.ignoredSpells = CooldownFlashDB.ignoredSpells or {}
            CooldownFlashDB.ignoredSpells[id] = true
            addInput:SetText("")
            addInput:ClearFocus()
            RefreshList()
        else
            addInput:SetText("Invalid ID")
            C_Timer.After(1, function() addInput:SetText("") end)
        end
    end

    addButton:SetScript("OnClick", AddSpell)
    addInput:SetScript("OnEnterPressed", AddSpell)
    container:SetScript("OnShow", RefreshList)

    return container
end
