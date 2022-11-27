local blurMat = Material("pp/blurscreen")
local HideHUD = false
local OpenMotherFrame = nil
local Dynamic = 0

local playlists = {
    {
        name = "Ambient",
        pltable = "chicagoRP.ambientplaylist"
    }, {
        artist = "IDM",
        pltable = "chicagoRP.idmplaylist"
    }
}

local function BlurBackground(panel)
    if (!IsValid(panel) or !panel:IsVisible()) then return end
    local layers, density, alpha = 1, 1, 100
    local x, y = panel:LocalToScreen(0, 0)
    local FrameRate, Num, Dark = 1 / RealFrameTime(), 5, 150

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(blurMat)

    for i = 1, Num do
        blurMat:SetFloat("$blur", (i / layers) * density * Dynamic)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end

    surface.SetDrawColor(0, 0, 0, Dark * Dynamic)
    surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    Dynamic = math.Clamp(Dynamic + (1 / FrameRate) * 7, 0, 1)
end

hook.Add("HUDPaint", "chicagoRP_vehicleradio_HideHUD", function()
    if HideHUD then
        return false
    end
end)

net.Receive("chicagoRP_vehicleradio", function()
    if IsValid(OpenMotherFrame) then return end
    local ply = LocalPlayer()
    local screenwidth = ScrW()
    local screenheight = ScrH()
    local CVarBlur = GetConVar("chicagoRP_blur"):GetBool()
    local CVarDSP = GetConVar("chicagoRP_dsp"):GetBool()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(300, 500)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(true)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("Vehicle Radio")
    motherFrame:ParentToHUD()
    HideHUD = true

    motherFrame:SetAlpha(0)
    motherFrame:AlphaTo(255, 0.15, 0)

    motherFrame:MakePopup()
    motherFrame:Center()

    function motherFrame:Paint(w, h)
        BlurBackground(self)
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 0))
        print("THIS SHOULD NOT PRINT WHEN FRAME IS CLOSED")
    end

    function motherFrame:OnClose()
        HideHUD = false
    end

    function motherFrame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_Q then
            self:AlphaTo(50, 0.15, 0)
            surface.PlaySound("chicagoRP_settings/back.wav")
            timer.Simple(0.15, function()
                if IsValid(self) then
                    self:Close()
                end
            end)
        end
    end

    local gameSettingsScrollPanel = vgui.Create("DScrollPanel", motherFrame)
    gameSettingsScrollPanel:Dock(FILL)

    for v in ipairs(playlists) do
        local categoryButton = gameSettingsScrollPanel:Add("DButton")
        categoryButton:SetText(v.name)
        categoryButton:Dock(TOP)
        categoryButton:DockMargin(0, 10, 0, 0)
        categoryButton:SetSize(200, 50)

        function categoryButton:DoClick()
            print(v.pltable)
        end
    end

    -- function gameSettingsScrollPanel:Paint(w, h)
    --     -- draw.RoundedBox(8, 0, 0, w, h, Color(200, 0, 0, 10))
    --     -- print(self:IsVisible())
    --     return nil
    -- end

    -- local gameSettingsScrollBar = gameSettingsScrollPanel:GetVBar() -- mr biden please legalize nuclear bombs
    -- gameSettingsScrollBar:SetHideButtons(true)
    -- gameSettingsScrollBar:SetPos(HorizontalScreenScale(525), VerticalScreenScale(185))
    -- function gameSettingsScrollBar:Paint(w, h)
    --     draw.RoundedBox(0, 0, 0, w, h, Color(42, 40, 35, 66))
    -- end
    -- function gameSettingsScrollBar.btnGrip:Paint(w, h)
    --     draw.RoundedBox(0, 0, 0, w, h, Color(76, 76, 74, 150))
    -- end

    OpenMotherFrame = motherFrame
end)

print("chicagoRP GUI loaded!")

-- to-do: