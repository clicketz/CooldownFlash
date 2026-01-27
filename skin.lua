local addonName, ns = ...

ns.Skin = {}
local group = nil

-- ----------------------------------------------------------------------------
-- Masque Registration
-- ----------------------------------------------------------------------------
function ns.Skin.Register(frame)
    local Masque = LibStub and LibStub("Masque", true)
    if not Masque then return end

    group = Masque:Group(addonName)

    -- Register all standard button regions so the skin can fully wrap the frame
    local buttonData = {
        Icon = frame.Icon,
        Cooldown = frame.Cooldown,
        Normal = frame.Normal,
        Pushed = frame.Pushed,
        Highlight = frame.Highlight,
    }

    group:AddButton(frame, buttonData, "Item")

    group:ReSkin()
end

-- ----------------------------------------------------------------------------
-- Trigger a re-skin (useful when resizing the frame)
-- ----------------------------------------------------------------------------
function ns.Skin.ReSkin()
    if group then
        group:ReSkin()
    end
end
