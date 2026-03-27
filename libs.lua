local _, ns = ...
ns.Libs = {}

-- Registry to track inputs so the Options Panel can refresh them on demand
local inputRegistry = {}

function ns.Libs.RefreshOptions()
    for _, element in ipairs(inputRegistry) do
        element:UpdateValue()
    end
end

function ns.Libs.CreateNumberInput(parent, label, key, updateFunc)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(60, 20)
    editbox:SetAutoFocus(false)

    local labelText = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("LEFT", editbox, "RIGHT", 10, 0)
    labelText:SetText(label)

    function editbox:UpdateValue()
        self:SetText(tostring(CooldownFlashDB[key]))
        self:SetCursorPosition(0)
    end

    editbox:SetScript("OnShow", function(self)
        self:UpdateValue()
    end)

    local function SaveValue(self)
        local val = tonumber(self:GetText())
        if val and val ~= CooldownFlashDB[key] then
            CooldownFlashDB[key] = val
            if updateFunc then updateFunc(val) end
        else
            self:UpdateValue()
        end
    end

    editbox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    editbox:SetScript("OnEditFocusLost", SaveValue)

    editbox:SetScript("OnEscapePressed", function(self)
        self:UpdateValue()
        self:ClearFocus()
    end)

    table.insert(inputRegistry, editbox)
    return editbox
end

function ns.Libs.CreateDropdown(parent, labelText, key, options, updateFunc)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(250, 25)

    local label = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)

    local dropdown = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    dropdown:SetWidth(100)

    function container:UpdateValue()
        dropdown:SetupMenu(function(owner, rootDescription)
            for _, opt in ipairs(options) do
                rootDescription:CreateRadio(
                    opt.name,
                    function()
                        return CooldownFlashDB[key] == opt.value
                    end,
                    function()
                        CooldownFlashDB[key] = opt.value
                        if updateFunc then updateFunc(opt.value) end
                    end
                )
            end
        end)
    end

    container:SetScript("OnShow", function(self)
        self:UpdateValue()
    end)

    table.insert(inputRegistry, container)
    return container
end

function ns.Libs.CreateBlacklistPanel(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(300, 400)
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    local title = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Ignored Spells")

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

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(240, 1)
    scrollFrame:SetScrollChild(content)

    local rowCache = {}

    local function GetRow(index)
        if not rowCache[index] then
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(240, 24)

            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(20, 20)
            row.icon:SetPoint("LEFT", 2, 0)

            row.delBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
            row.delBtn:SetSize(24, 24)
            row.delBtn:SetPoint("RIGHT", 0, 0)

            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
            row.text:SetPoint("RIGHT", row.delBtn, "LEFT", -5, 0)
            row.text:SetJustifyH("LEFT")

            rowCache[index] = row
        end
        return rowCache[index]
    end

    local function RefreshList()
        for _, row in ipairs(rowCache) do
            row:Hide()
        end

        local spells = {}
        local dbSpells = CooldownFlashDB.ignoredSpells

        for id in pairs(dbSpells) do
            local info = C_Spell.GetSpellInfo(id)
            table.insert(spells, {
                id = id,
                name = info and info.name or ("Unknown ID: " .. id),
                icon = info and info.iconID or 134400
            })
        end
        table.sort(spells, function(a, b) return a.name < b.name end)

        local lastRow = nil
        for i, spell in ipairs(spells) do
            local row = GetRow(i)

            row.icon:SetTexture(spell.icon)
            row.text:SetText(spell.name .. " |cff888888(" .. spell.id .. ")|r")

            row.delBtn:SetScript("OnClick", function()
                CooldownFlashDB.ignoredSpells[spell.id] = nil
                RefreshList()
            end)

            row:ClearAllPoints()
            if lastRow then
                row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -2)
            else
                row:SetPoint("TOPLEFT", 0, 0)
            end

            row:Show()
            lastRow = row
        end
        content:SetHeight(math.max(#spells * 26, 10))
    end

    local function AddSpell()
        local id = tonumber(addInput:GetText())
        if id and C_Spell.GetSpellInfo(id) then
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

    container.UpdateValue = RefreshList
    table.insert(inputRegistry, container)

    return container
end
