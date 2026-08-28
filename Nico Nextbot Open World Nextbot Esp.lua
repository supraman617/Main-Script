-- SERVICES
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer

-- SETTINGS
local ESP_COLOR = Color3.fromRGB(0, 255, 0)
local BASE_WIDTH = 60
local BASE_HEIGHT = 90
local SCALE_MULTIPLIER = 1.4

-- DATA
local EspObjects = {}

-- 🔑 Keybind setiap nn_
local NN_KEYBINDS = {
	nn_airport   = Enum.KeyCode.Z,
	nn_backrooms = Enum.KeyCode.X,
	nn_hotel     = Enum.KeyCode.C,
	nn_outpost   = Enum.KeyCode.V,
	nn_poolrooms = Enum.KeyCode.B,
	nn_port      = Enum.KeyCode.N,
	nn_russia    = Enum.KeyCode.M,
	nn_tunnels   = Enum.KeyCode.Comma,
	nn_mall      = Enum.KeyCode.Period,
}

-- Default OFF
local FolderEnabled = {}
for name,_ in pairs(NN_KEYBINDS) do
	FolderEnabled[name] = false
end

-- DRAWING HELPER
local function NewDrawing(type, props)
	local obj = Drawing.new(type)
	for i,v in pairs(props) do
		obj[i] = v
	end
	return obj
end

-- VALID BOT
local function IsValidBot(model)
	return model:IsA("Model") and model:FindFirstChild("HumanoidRootPart")
end

-- CREATE ESP
local function CreateESP(model, folderName)
	if EspObjects[model] then return end

	local box = NewDrawing("Square", {
		Color = ESP_COLOR,
		Thickness = 2,
		Filled = false,
		Transparency = 1,
		Visible = false
	})

	local text = NewDrawing("Text", {
		Color = ESP_COLOR,
		Size = 16,
		Center = true,
		Outline = true,
		Text = model.Name,
		Visible = false
	})

	EspObjects[model] = {
		Box = box,
		Text = text,
		Folder = folderName
	}
end

local function RemoveESP(model)
	if EspObjects[model] then
		EspObjects[model].Box:Remove()
		EspObjects[model].Text:Remove()
		EspObjects[model] = nil
	end
end

-- SCAN FOLDER
local function ScanFolder(folder)
	local folderName = folder.Name

	for _,v in pairs(folder:GetChildren()) do
		if IsValidBot(v) then
			CreateESP(v, folderName)
		end
	end

	folder.ChildAdded:Connect(function(v)
		if IsValidBot(v) then
			CreateESP(v, folderName)
		end
	end)

	folder.ChildRemoved:Connect(function(v)
		RemoveESP(v)
	end)
end

-- 📂 BOTS
local BotsFolder = Workspace:FindFirstChild("bots")
if not BotsFolder then
	warn("❌ Folder 'bots' tak jumpa")
	return
end

for folderName,_ in pairs(NN_KEYBINDS) do
	local folder = BotsFolder:FindFirstChild(folderName)
	if folder then
		ScanFolder(folder)
	end
end

-- 🎮 KEYBINDS
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	for folderName,key in pairs(NN_KEYBINDS) do
		if input.KeyCode == key then
			FolderEnabled[folderName] = not FolderEnabled[folderName]
			print(folderName, FolderEnabled[folderName] and "ON" or "OFF")
		end
	end
end)

-- 🎯 RENDER ESP
RunService.RenderStepped:Connect(function()
	for model,esp in pairs(EspObjects) do
		if not FolderEnabled[esp.Folder] then
			esp.Box.Visible = false
			esp.Text.Visible = false
			continue
		end

		local hrp = model:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if onScreen then
			local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
			local scale = math.clamp(1 / (distance / 40), 0.6, 1.8)

			local width = BASE_WIDTH * scale * SCALE_MULTIPLIER
			local height = BASE_HEIGHT * scale * SCALE_MULTIPLIER

			esp.Box.Size = Vector2.new(width, height)
			esp.Box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
			esp.Box.Visible = true

			esp.Text.Position = Vector2.new(pos.X, pos.Y - height/2 - 14)
			esp.Text.Visible = true
		else
			esp.Box.Visible = false
			esp.Text.Visible = false
		end
	end
end)

-- =========================
-- 🧩 GUI KEYBIND DISPLAY
-- =========================

local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
gui.Name = "ESP_Keybind_GUI"
gui.ResetOnSpawn = false

-- MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260, 260)
frame.Position = UDim2.fromScale(0.02, 0.3)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,32)
title.BackgroundTransparency = 1
title.Text = "ESP Keybinds"
title.TextColor3 = Color3.fromRGB(0,255,0)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local list = Instance.new("UIListLayout", frame)
list.Padding = UDim.new(0,6)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Top

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	frame.Size = UDim2.fromOffset(260, list.AbsoluteContentSize.Y + 40)
end)

for name,key in pairs(NN_KEYBINDS) do
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0.95,0,0,24)
	lbl.BackgroundColor3 = Color3.fromRGB(35,35,35)
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.Text = name .. "  :  " .. key.Name
	lbl.BorderSizePixel = 0

	local c = Instance.new("UICorner", lbl)
	c.CornerRadius = UDim.new(0,6)
end

-- =========================
-- 🔘 TOGGLE BUTTON (DRAG)
-- =========================

local toggleBtn = Instance.new("Frame", gui)
toggleBtn.Size = UDim2.fromOffset(110, 34)
toggleBtn.Position = UDim2.fromScale(0.02, 0.25)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.BorderSizePixel = 0
toggleBtn.Active = true
toggleBtn.Draggable = true

local tc = Instance.new("UICorner", toggleBtn)
tc.CornerRadius = UDim.new(0, 10)

local btnText = Instance.new("TextButton", toggleBtn)
btnText.Size = UDim2.fromScale(1,1)
btnText.BackgroundTransparency = 1
btnText.Text = "Hide ESP UI"
btnText.TextColor3 = Color3.fromRGB(0,255,0)
btnText.Font = Enum.Font.GothamBold
btnText.TextSize = 14

btnText.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	btnText.Text = frame.Visible and "Hide ESP UI" or "Show ESP UI"
end)

print("ESP Bots Loaded (GUI + Toggle Button)")
