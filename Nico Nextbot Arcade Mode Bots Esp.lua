-- SERVICES
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- SETTINGS
local ESP_ENABLED = true
local ESP_COLOR = Color3.fromRGB(0, 255, 0)

local BASE_WIDTH = 60
local BASE_HEIGHT = 90
local SCALE_MULTIPLIER = 1.4

-- ESP STORAGE (KEY = MODEL)
local EspObjects = {}

-- =========================
-- DRAWING HELPER
-- =========================
local function NewDrawing(type, props)
	local obj = Drawing.new(type)
	for i, v in pairs(props) do
		obj[i] = v
	end
	return obj
end

-- =========================
-- GET ROOT PART FROM MODEL
-- =========================
local function GetRootPart(model)
	if not model or not model:IsA("Model") then return nil end

	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart")
end

-- =========================
-- CREATE ESP FOR MODEL
-- =========================
local function CreateESP(model)
	if EspObjects[model] then return end
	if not model:IsA("Model") then return end

	local root = GetRootPart(model)
	if not root then return end

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
		Text = model.Name, -- ✅ NAMA ASAL
		Visible = false
	})

	EspObjects[model] = {
		Box = box,
		Text = text
	}
end

-- =========================
-- REMOVE ESP
-- =========================
local function RemoveESP(model)
	local esp = EspObjects[model]
	if esp then
		pcall(function()
			esp.Box:Remove()
			esp.Text:Remove()
		end)
		EspObjects[model] = nil
	end
end

-- =========================
-- BOTS FOLDER
-- =========================
local BotsFolder = Workspace:FindFirstChild("bots")
if not BotsFolder then
	warn("❌ Folder 'bots' tak jumpa")
	return
end

-- Initial scan (MODEL SAHAJA)
for _, obj in ipairs(BotsFolder:GetChildren()) do
	if obj:IsA("Model") then
		CreateESP(obj)
	end
end

-- Auto detect spawn
BotsFolder.ChildAdded:Connect(function(obj)
	if obj:IsA("Model") then
		task.wait(0.1) -- bagi masa parts load
		CreateESP(obj)
	end
end)

-- Auto cleanup
BotsFolder.ChildRemoved:Connect(function(obj)
	RemoveESP(obj)
end)

-- =========================
-- RENDER ESP
-- =========================
RunService.RenderStepped:Connect(function()
	if not ESP_ENABLED then return end

	for model, esp in pairs(EspObjects) do
		local root = GetRootPart(model)

		if not root or not root.Parent then
			esp.Box.Visible = false
			esp.Text.Visible = false
			continue
		end

		local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
		if onScreen then
			local distance = (Camera.CFrame.Position - root.Position).Magnitude
			local scale = math.clamp(1 / (distance / 40), 0.6, 1.8)

			local width = BASE_WIDTH * scale * SCALE_MULTIPLIER
			local height = BASE_HEIGHT * scale * SCALE_MULTIPLIER

			esp.Box.Size = Vector2.new(width, height)
			esp.Box.Position = Vector2.new(
				pos.X - width / 2,
				pos.Y - height / 2
			)
			esp.Box.Visible = true

			esp.Text.Text = model.Name -- ✅ CONFIRM NAMA ASAL
			esp.Text.Position = Vector2.new(
				pos.X,
				pos.Y - height / 2 - 14
			)
			esp.Text.Visible = true
		else
			esp.Box.Visible = false
			esp.Text.Visible = false
		end
	end
end)

print("✅ Nico Nextbots ESP Loaded (Model-based, Nama Asal)")
