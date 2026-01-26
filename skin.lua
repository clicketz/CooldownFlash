local addonName, ns = ...

ns.Skin = {}

-- ----------------------------------------------------------------------------
-- Masque Registration
-- ----------------------------------------------------------------------------
function ns.Skin.Register(frame)
    -- Check if Masque is loaded without hard-crashing if LibStub is missing
    local Masque = LibStub and LibStub("Masque", true)
    if not Masque then return end

    -- Create a group for the addon
    local group = Masque:Group(addonName)

    -- Register the frame.
    -- Masque expects the frame to have regions named .Icon and .Cooldown
    -- (We standardized these names in core.lua to avoid passing a mapping table here)
    group:AddButton(frame)

    -- Apply the skin immediately
    group:ReSkin()
end
