if AutoExecute then
    if queue_on_teleport then
        queue_on_teleport(myScript)
    end
end

----\\ Services //----
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or game.Players.LocalPlayer
local Character = LocalPlayer.Character
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Controllers = ReplicatedStorage.Controllers
local Modules = ReplicatedStorage.Modules
local FishingController = require(Controllers.FishingController)
local AnimationController = require(Controllers.AnimationController)
local AutoFishingController = require(Controllers.AutoFishingController)
local RaycastUtility = require(ReplicatedStorage.Shared.RaycastUtility)
local ClientReplion = require(ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Client.ClientReplion)
local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local workspace = game:GetService("Workspace")
local barFishing = LocalPlayer.PlayerGui.Fishing.Main
----\\ Animations //----
local Humanoid = Character.Humanoid
local Cast = Instance.new("Animation") --- CastFromFullChargePosition1Hand
Cast.AnimationId = "rbxassetid://92624107165273"
local TrackCast = Humanoid:LoadAnimation(Cast) --- Length = 0.966
local Reel = Instance.new("Animation") --- FishingRodReelIdle
Reel.AnimationId = "rbxassetid://134965425664034" --- Looped
local TrackReel = Humanoid:LoadAnimation(Reel) --- Length = 1.316
local Start = Instance.new("Animation") --- StartChargingRod1Hand
Start.AnimationId = "rbxassetid://139622307103608"
local TrackStart = Humanoid:LoadAnimation(Start) --- Length = 2.683
----\\ Toggles //----
local MainToggle = {
    AutoFishing = false,
    InstantCatch = false,
    AutoSell = false,
    AutoTeleportToEvent = false,
    UseOxygenTank = false,
    UseRadar = false,
}
----\\ Variables //----
local MainVariable = {
    ModeFishing = "Remote",
    AllowCastAnimation = false,
    StillFishing = false,
    SellDelay = 1,
    MinigameActive = false
}
local IslandLocation = {}
for i, v in pairs(workspace["!!!! ISLAND LOCATIONS !!!!"]:GetChildren()) do
    if v:IsA("Part") or v:IsA("MeshPart") then
        table.insert(IslandLocation, v.Name)
    end
end
local SelectedIsland = ""
----\\ Functions //----
local Functions = {}
local RunFunctions = {}

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char.Humanoid
    Cast = Instance.new("Animation") --- CastFromFullChargePosition1Hand
    Cast.AnimationId = "rbxassetid://92624107165273"
    TrackCast = Humanoid:LoadAnimation(Cast) --- Length = 0.966
    Reel = Instance.new("Animation") --- FishingRodReelIdle
    Reel.AnimationId = "rbxassetid://134965425664034" --- Looped
    TrackReel = Humanoid:LoadAnimation(Reel) --- Length = 1.316
    Start = Instance.new("Animation") --- StartChargingRod1Hand
    Start.AnimationId = "rbxassetid://139622307103608"
    TrackStart = Humanoid:LoadAnimation(Start)
end)

Functions.NotificationCallback = function(Text)
    if Text == "Yes" then
        FishingController:RequestClientStopFishing()
    elseif Text == "No" then
    end
end

local Bind = Instance.new("BindableFunction")
Bind.OnInvoke = Functions.NotificationCallback

local Fishing = FishingController
local OriginalFishingMinigame = Fishing.RequestFishingMinigameClick
local OriginalFishingStopped = Fishing.FishingStopped
local OriginalSendFishingRequest = Fishing.SendFishingRequestToServer
local OriginalFishingMinigameChanged = Fishing.FishingMinigameChanged
local OriginalStopAnimation = AnimationController.StopAnimation
local OriginalAutoFishing = AutoFishingController.AutoFishingStateChanged
Functions.HookFishingController = function()
    if not MainToggle.AutoFishing then
        Fishing.FishingMinigameChanged = OriginalFishingMinigameChanged
        Fishing.RequestFishingMinigameClick = OriginalFishingMinigame
        Fishing.SendFishingRequestToServer = OriginalSendFishingRequest
        Fishing.FishingStopped = OriginalFishingStopped
        AnimationController.StopAnimation = OriginalStopAnimation
        AutoFishingController.AutoFishingStateChanged = OriginalAutoFishing
        return
    end
    Fishing.RequestFishingMinigameClick = function(self, ...)
        if MainToggle.InstantCatch then
            Net:WaitForChild("RE/FishingCompleted")
        end
        return OriginalFishingMinigame(self, ...)
    end
    Fishing.SendFishingRequestToServer = function(self, pos, power, ...)
        power = 1
        MainVariable.MinigameActive = true
        task.spawn(function()
            while MainVariable.MinigameActive do
                Fishing:RequestFishingMinigameClick()
                task.wait(0.1)
            end
        end)
        return OriginalSendFishingRequest(self, pos, power, ...)
    end
    Fishing.FishingStopped = function(self, ...)
        MainVariable.MinigameActive = false
        return OriginalFishingStopped(self, ...)
    end
    AnimationController.StopAnimation = function(self, anima, ...)
        if anima == "FishingRodReelIdle" then
            return
        end
        return OriginalStopAnimation(self, anima, ...)
    end
    AutoFishingController.AutoFishingStateChanged = function(self, isActive, ...)
        return
    end
end


Functions.StopAllTracks = function()
    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

Functions.GetExclaim = function()
    for _, v in pairs(workspace["!!! MENU RINGS"]:GetChildren()) do
        if v.Name == "TextEffectAttachment" and (v.Position.Y - Character.Head.Position.Y) <= 3 then
            v.AncestryChanged:Wait()
            return true
        end
    end
    return false
end

Functions.HelperRemote = function()
    local CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    local RaycastParams = RaycastParams.new()
    RaycastParams.IgnoreWater = true
    RaycastParams.RespectCanCollide = false
    RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParams.FilterDescendantsInstances = RaycastUtility:getFilteredTargets(LocalPlayer)
    local workspace_Spherecast = workspace:Spherecast((CFrame + CFrame.LookVector * 12).Position, 2, Vector3.new(0, -125, 0), RaycastParams)
    return workspace_Spherecast.Position.Y
end

local Origin_GetExpect = ClientReplion.GetExpect
local Origin_Get = ClientReplion.Get
local Origin_OnChange = ClientReplion.OnChange
local Origin_Send = FishingController.SendFishingRequestToServer
local Origin_Click = FishingController.RequestFishingMinigameClick
local Origin_Stop = FishingController.FishingStopped
ClientReplion.GetExpect = function(self, path, ...)
    if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
        return true
    end
    return Origin_GetExpect(self, path, ...)
end
ClientReplion.Get = function(self, path, ...)
    if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
        return true
    end
    return Origin_Get(self, path, ...)
end
ClientReplion.OnChange = function(self, path, ...)
    if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
        return true
    end
    return Origin_OnChange(self, path, ...)
end
FishingController.SendFishingRequestToServer = function(self, pos, power, ...)
    if MainToggle.AutoFishing then
        power = 1
    end
    local result = {Origin_Send(self, pos, power, ...)}
    MainVariable.MinigameActive = true
    task.spawn(function()
        while MainVariable.MinigameActive and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" do
            FishingController.RequestFishingMinigameClick()
            task.wait(0.1)
        end
    end)
    return unpack(result)
end
FishingController.RequestFishingMinigameClick = function(self, ...)
    if MainToggle.InstantCatch then
        return Net:WaitForChild("RF/FishingCompleted"):InvokeServer()
    end
    return Origin_Click(self, ...)
end
FishingController.FishingStopped = function(self, ...)
    MainVariable.MinigameActive = false
    return Origin_Stop(self, ...)
end

Functions.LegitMode = function()
    if not MainToggle.AutoFishing then
        ClientReplion.GetExpect = Origin_GetExpect
        ClientReplion.Get = Origin_Get
        ClientReplion.OnChange = Origin_OnChange
        FishingController.SendFishingRequestToServer = Origin_Send
        FishingController.RequestFishingMinigameClick = Origin_Click
        FishingController.FishingStopped = Origin_Stop
        return
    end
    ClientReplion.GetExpect = function(self, path, ...)
        if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
            return true
        end
        return Origin_GetExpect(self, path, ...)
    end
    ClientReplion.Get = function(self, path, ...)
        if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
            return true
        end
        return Origin_Get(self, path, ...)
    end
    ClientReplion.OnChange = function(self, path, ...)
        if tostring(path) == "AutoFishing" and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" then
            return true
        end
        return Origin_OnChange(self, path, ...)
    end
    FishingController.SendFishingRequestToServer = function(self, pos, power, ...)
        power = 1
        local result = {Origin_Send(self, pos, power, ...)}
        MainVariable.MinigameActive = true
        task.spawn(function()
            while MainVariable.MinigameActive and MainToggle.AutoFishing and MainVariable.ModeFishing == "Legit" do
                FishingController.RequestFishingMinigameClick()
                task.wait(0.1)
            end
        end)
        return unpack(result)
    end
    FishingController.RequestFishingMinigameClick = function(self, ...)
        if MainToggle.InstantCatch then
            return Net:WaitForChild("RF/FishingCompleted"):InvokeServer()
        end
        return Origin_Click(self, ...)
    end
    FishingController.FishingStopped = function(self, ...)
        MainVariable.MinigameActive = false
        return Origin_Stop(self, ...)
    end
end

Functions.FishingMinigame = function()
    MainVariable.MinigameActive = true

    local startTime = tick()
    while workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) 
      and barFishing.Position.Y.Scale >= 0.9 do

        if not MainToggle.InstantCatch then
            FishingController:RequestFishingMinigameClick()
            task.wait(0.1)
        else
            Net:FindFirstChild("RE/FishingCompleted"):FireServer()
            task.wait(0.1)
        end

        -- Watchdog: kalau stuck > 10 detik, paksa keluar
        if tick() - startTime > 10 then
            warn(">> FishingMinigame stuck, forcing exit")
            break
        end

        task.wait()
    end
    MainVariable.StillFishing = false
    MainVariable.MinigameActive = false

    if TrackReel.IsPlaying then
        TrackReel:Stop()
    end
    if FishingController.FishingStopped then
        FishingController:FishingStopped()
    end

    print("[DEBUG] Finished FishingMinigame → reset state")
end

Functions.ForceRelease = function(powerOverride)
    local power = FishingController:_getPower()
    if powerOverride then
        power = powerOverride
    end
    local sendSuccess, data = FishingController:SendFishingRequestToServer(Vector2.new(0,0), power)
    if sendSuccess then
        FishingController:FishingRodStarted(data)
        while workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) and barFishing.Position.Y.Scale < 0.9 do
            task.wait()
        end
        if barFishing.Position.Y.Scale >= 0.9 then
            Functions.FishingMinigame()
        end
    end
end

Functions.LegitModeOnly1Time = function()
    if not MainVariable.StillFishing then
        MainVariable.StillFishing = true

        -- Kalau belum ada pancing, mulai charge baru
        if not workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) 
        and Functions.HelperRemote() then

            print("[DEBUG] Starting charge...")
            FishingController:RequestChargeFishingRod()

            repeat task.wait() until FishingController:_getPower() > 0

            local conn
            conn = RunService.Heartbeat:Connect(function()
                local p = FishingController:_getPower()
                if p >= 0.95 then
                    print("[DEBUG] ForceRelease triggered")
                    Functions.ForceRelease(p)
                    conn:Disconnect()
                end
            end)

        -- Kalau masih dalam state fishing (cosmetic ada)
        elseif workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
            if barFishing.Position.Y.Scale >= 0.9 then
                print("[DEBUG] Entering FishingMinigame")
                Functions.FishingMinigame()

                -- Setelah minigame selesai, power reset ke 0
                -- Jadi langsung request charge ulang di sini
                task.delay(0.5, function()
                    if FishingController:_getPower() == 0 then
                        print("[DEBUG] Recharging after minigame...")
                        MainVariable.StillFishing = false
                        Functions.LegitMode()
                    end
                end)
            end
        else
            MainVariable.StillFishing = false
        end
    end
end

Functions.LegitModekw = function()
    MainVariable.StillFishing = true
    local function ForceRelease(powerOverride)
        local power = FishingController:_getPower()
        if powerOverride then
            power = powerOverride
        end
        local sendSuccess, data = FishingController:SendFishingRequestToServer(Vector2.new(0,0), power)
        if sendSuccess then
            FishingController:FishingRodStarted(data)
            AnimationController:DestroyActiveAnimationTracks()
            AnimationController:PlayAnimation("CastFromFullChargePosition1Hand")
            MainVariable.StillFishing = false
            while workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) do
                FishingController:RequestFishingMinigameClick()
                task.wait(0.1)
            end
            MainVariable.StillFishing = false
            print("[DEBUG]", MainVariable.StillFishing)
        else
            FishingController:FishingStopped()
            MainVariable.StillFishing = false
            print("[DEBUG]", MainVariable.StillFishing)
        end
    end
    local function AutoChargeAndRelease()
        FishingController:RequestChargeFishingRod()
        task.spawn(function()
            repeat task.wait() until FishingController._getPower(FishingController) > 0
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local p = FishingController:_getPower()
                if p >= 0.95 then
                    ForceRelease(p)
                    conn:Disconnect()
                end
            end)
        end)
    end
    task.wait(0.2)
    AutoChargeAndRelease()
end


Functions.LegitModeLowBudget = function()
    local function ForceRelease(powerOverride)
        local power = FishingController:_getPower()
        if powerOverride then
            power = powerOverride
        end
        local sendSuccess, data = FishingController:SendFishingRequestToServer(Vector2.new(0,0), power)
        if sendSuccess then
            FishingController:FishingRodStarted(data)
            while not barFishing.Position.Y.Scale < 0.9 do
                task.wait()
            end
            while barFishing.Position.Y.Scale >= 0.9 do
                FishingController:RequestFishingMinigameClick()
                task.wait(0.1)
            end
        end
        MainVariable.StillFishing = false
    end
    local function AutoChargeAndRelease()
        MainVariable.StillFishing = true
        FishingController:RequestChargeFishingRod()
        task.spawn(function()
        repeat task.wait() until FishingController._getPower(FishingController) > 0
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local p = FishingController:_getPower()
                if p >= 0.95 then
                    ForceRelease(p)
                    TrackCast:Play()
                    conn:Disconnect()
                end
                task.wait()
            end)
        end)
    end
    task.wait(0.1)
    AutoChargeAndRelease()
end

Functions.RemoteMode = function()
    if not MainVariable.StillFishing then
        MainVariable.StillFishing = true
        if not workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
            while not workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) do
                TrackStart:Play()
                task.wait(0.1)
                Net:FindFirstChild("RF/ChargeFishingRod"):InvokeServer(workspace:GetServerTimeNow())
                if Functions.HelperRemote then
                    TrackStart:Stop()
                    TrackCast:Play()
                    Net:FindFirstChild("RF/RequestFishingMinigameStarted"):InvokeServer(Functions.HelperRemote(), 0.95392849132)
                    TrackCast:Stop()
                    task.wait(0.1)
                    TrackReel:Play()
                end
            end
            if Functions.GetExclaim() then
                task.wait(0.5)
                Net:FindFirstChild("RE/FishingCompleted"):FireServer()
                task.wait(0.1)
                TrackReel:Stop()
            else
                repeat task.wait() until Functions.GetExclaim()
                task.wait(0.5)
                Net:FindFirstChild("RE/FishingCompleted"):FireServer()
                task.wait(0.1)
                TrackReel:Stop()
            end
        elseif workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
            TrackReel:Play()
            while workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) do
                Net:FindFirstChild("RE/FishingCompleted"):FireServer()task.wait(0.8)
                task.wait(0.1)
            end
            TrackReel:Stop()
        end
        MainVariable.StillFishing = false
    end
end

Functions.RemoteModeLowVersion = function()
    local animator = Character.Humanoid.Animator
    local anim = Modules.Animations.CaughtFish1
    local track = animator:LoadAnimation(anim)
    MainVariable.StillFishing = true
    repeat task.wait(0.1)
    Net:FindFirstChild("RF/ChargeFishingRod"):InvokeServer(workspace:GetServerTimeNow())
    anim = Modules.Animations.StartChargingRod1Hand
    track = animator:LoadAnimation(anim)
    track:Play()
    local CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    local RaycastParams = RaycastParams.new()
    RaycastParams.IgnoreWater = true
    RaycastParams.RespectCanCollide = false
    RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParams.FilterDescendantsInstances = RaycastUtility:getFilteredTargets(LocalPlayer)
    local workspace_Spherecast = workspace:Spherecast((CFrame + CFrame.LookVector * 12).Position, 2, Vector3.new(0, -125, 0), RaycastParams)
    track.Stopped:Wait()
    Net:FindFirstChild("RF/RequestFishingMinigameStarted"):InvokeServer(workspace_Spherecast.Position.Y, 0.95392849132)
    print("Berhasil memfire remote RequestFishingMinigameStarted")
    anim = Modules.Animations.CastFromFullChargePosition1Hand
    track = animator:LoadAnimation(anim)
    track:Play()
    track:Play()
    until workspace.CosmeticFolder:FindFirstChild(LocalPlayer.UserId)
    if not workspace.CosmeticFolder:FindFirstChild(LocalPlayer.UserId) then return end
    track.Stopped:Wait()
    anim = Modules.Animations.FishingRodReelIdle
    track = animator:LoadAnimation(anim)
    track:Play()
    track:Play()
    for _, animation in pairs(animator:GetPlayingAnimationTracks()) do
        if animation.Animation.AnimationId == Modules.Animations.FishingRodReelIdle.AnimationId then
            local trigger = false
            repeat task.wait()
                if Functions.GetExclaim() then
                    trigger = true
                end
            until trigger == true
            task.wait(1)
            Net:FindFirstChild("RE/FishingCompleted"):FireServer()
            print("[DEBUG] Successfully Fire Remote FishingCompleted")
            anim = Modules.Animations.CaughtFish1
            track = animator:LoadAnimation(anim)
            track:Play()
        end
    end
    mainvariable.stillFishing = false
end

local notif = 0
local alreadydo = 0
RunFunctions.AutoFishing = function(state)
    MainToggle.AutoFishing = state
    if MainToggle.AutoFishing then
        Functions.HookFishingController()
        while MainToggle.AutoFishing do
            if alreadydo == 0 and MainVariable.ModeFishing == "Legit" and not MainVariable.StillFishing and not workspace.CosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
                alreadydo = alreadydo + 1
            elseif MainVariable.ModeFishing == "Remote" and not MainVariable.StillFishing then
                if alreadydo >= 0 then
                    alreadydo = 0
                end
                local success, err = pcall(function()
                    Functions.RemoteMode()
                end)
                if not success then
                    print("[DEBUG] Fishing Remote Mode Error : " .. err)
                    MainVariable.StillFishing = false
                end
            end
            task.wait(0.1)
        end
    else
        Functions.HookFishingController()
        if notif >= 1 then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Do you want stop fishing?";
                Text = "Yes will force stop you fishing right now";
                Icon = ""; -- Optional: Replace with a valid asset ID for an icon
                Duration = 5; -- Optional: How long the notification stays on screen (in seconds)
                Button1 = "Yes";
                Button2 = "No";
                Callback = Bind;
            })
        end
        if notif == 0 then
            notif = notif + 1
        end
        MainVariable.StillFishing = false
    end
end

RunFunctions.AutoSell = function(state)
    MainToggle.AutoSell = state
    if MainToggle.AutoSell then
        while MainToggle.AutoSell do
            task.wait(MainVariable.SellDelay)
            Net:WaitForChild("RF/SellAllItems"):InvokeServer()
        end
    end
end

RunFunctions.UseOxygenTank = function(state)
    MainToggle.UseOxygenTank = state
    if MainToggle.UseOxygenTank then
        Net:WaitForChild("RF/EquipOxygenTank"):InvokeServer(105)
    else
        Net:WaitForChild("RF/UnequipOxygenTank"):InvokeServer()
    end
end

RunFunctions.UseRadar = function(state)
    MainToggle.UseRadar = state
    if MainToggle.UseRadar then
        Net:WaitForChild("RF/UpdateFishingRadar"):InvokeServer(true)
    else
        Net:WaitForChild("RF/UpdateFishingRadar"):InvokeServer(false)
    end
end

-- Fungsi cari titik terendah di island
local function GetLowestPoint(model)
    local lowestY = math.huge
    local lowestPart

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- hanya ambil part yang bisa ditabrak & bisa diquery
            if obj.CanCollide and obj.CanQuery then
                -- hitung titik paling bawah dari part
                local bottomY = (obj.Position - Vector3.new(0, obj.Size.Y/2, 0)).Y
                if bottomY < lowestY then
                    lowestY = bottomY
                    lowestPart = obj
                end
            end
        end
    end

    if lowestPart then
        -- kembalikan posisi di atas part terendah
        return Vector3.new(lowestPart.Position.X, lowestY, lowestPart.Position.Z)
    end
    return nil
end

-- Fungsi teleport ke island
RunFunctions.TeleportToIslandte = function()
    if not Character then
        return
    end

    for _, target in pairs(workspace["!!!! ISLAND LOCATIONS !!!!"]:GetChildren()) do
        if target.Name == SelectedIsland then
            local island = workspace.Islands:FindFirstChild(SelectedIsland)
            if not island then
                warn("Island tidak ditemukan di workspace.Islands:", SelectedIsland)
                return
            end

            local groundPos = GetLowestPoint(island)
            if groundPos then
                print("[DEBUG] Teleport ke titik terendah:", groundPos)
                Character:MoveTo(groundPos + Vector3.new(0, 10, 0)) -- spawn sedikit di atas tanah
            else
                warn("[DEBUG] Tidak ada part valid, fallback ke target.Position")
                Character:MoveTo(target.Position)
            end
        end
    end
end

RunFunctions.TeleportToIsland = function()
    if not Character then
        return
    end
    for _, target in pairs(workspace["!!!! ISLAND LOCATIONS !!!!"]:GetChildren()) do
        if target.Name == SelectedIsland then
            local RayOrigin = target.Position
            local RayDirection = Vector3.new(0, -100000000, 0)
            local RaycastParams = RaycastParams.new()
            RaycastParams.FilterDescendantsInstances = {target, Character}
            RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            local oldHit, oldPos = workspace:FindPartOnRay(Ray.new(RayOrigin, RayDirection))
            print("Legacy FindPartOnRay:", oldHit, oldPos)
            local result = workspace:Raycast(RayOrigin, RayDirection, RaycastParams)
            print("[DEBUG] Result Raycast : ", tostring(result))
            print("[DEBUG] Raycast Origin : ", tostring(RayOrigin))
            print("[DEBUG] Raycast Direction : ", tostring(RayDirection))
            if result then
                local hitPos = result.Position or result:GetPivot().Position
                Charactet:MoveTo(hitPos + Vector3.new(0, 10, 0))
            else
                Character:MoveTo(target.Position - Vector3.new(0, 150, 0))
            end
        end
    end
end

local eventcon
RunFunctions.TeleportToEvent = function(state)
    MainToggle.TeleportToEvent = state
    if MainToggle.TeleportToEvent then
        for _, v in pairs(workspace:GetChildren()) do 
            if v.Name == "Props" then
                for _, display in pairs(v:GetDescendants()) do 
                    if v.Name == "DisplayName" and v:IsA("TextLabel") then 
                        MainVariable.PositionEvent = v:GetPivot().Position or v.Position
                    end
                end
            end
        end
        eventcon = workspace.ChildAdded:Connect(function(v)
            if v.Name == "Props" then
                for _, display in pairs(v:GetDescendants()) do 
                    if v.Name == "DisplayName" and v:IsA("TextLabel") then 
                        MainVariable.PositionEvent = v:GetPivot().Position or v.Position
                    end
                end
            end
        end)
        while MainToggle.TeleportToEvent do 
            if Character.Humanoid.Position 
        
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nevcit/UI-Library/refs/heads/main/Loadstring/Fluent1.2.2.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Goa Hub | Fish It",
    SubTitle = "by Nevcit",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 380),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

-- Fluent provides Lucide Icons, they are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    User = Window:AddTab({ Title = "LocalPlayer", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "teleport" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddDropdown("Mode", {
    Title = "Mode",
    Description = "",
    Values = {"Legit", "Remote"},
    Multi = false,
    Default = 2,
    Callback = function(Value)
        MainVariable.ModeFishing = Value
    end
})

Tabs.Main:AddToggle("AutoFishing", 
{
    Title = "Auto Fishing", 
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            RunFunctions.AutoFishing(state)
        end)
    end 
})

Tabs.Main:AddToggle("AutoSellAll", 
{
    Title = "Auto Sell All", 
    Description = "This will sell all your fish except favorite fish",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            RunFunctions.AutoSell(state)
        end)
    end 
})

Tabs.User:AddToggle("UseDivingMask", 
{
    Title = "Use Diving Mask For Free", 
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            RunFunctions.UseOxygenTank(state)
        end)
    end 
})

Tabs.User:AddToggle("UseRadar", 
{
    Title = "Use Radar For Free", 
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            RunFunctions.UseRadar(state)
        end)
    end 
})

Tabs.Teleport:AddDropdown("SelectIsland", {
    Title = "Select Island",
    Description = "",
    Values = IslandLocation,
    Multi = false,
    Default = "",
    Callback = function(Value)
        SelectedIsland = Value
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport To Island",
    Description = "",
    Callback = function()
        RunFunctions.TeleportToIsland()
    end
})
