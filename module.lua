local module = {}

local pls = game:GetService("Players")
local lp = pls.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local runs = game:GetService("RunService")

local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
	char = c
	hrp = c:FindFirstChild("HumanoidRootPart")
	hum = c:FindFirstChild("Humanoid")
	module.char = char
	module.hrp = hrp
	module.hum = hum
end)

module.char = char
module.hrp = hrp
module.hum = hum

local ce = rs:FindFirstChild("CharacterEvents")
local ge = rs:FindFirstChild("GrabEvents")

local setowner = ge and ge:FindFirstChild("SetNetworkOwner")
local cline = ge and ge:FindFirstChild("CreateGrabLine")
local dline = ge and ge:FindFirstChild("DestroyGrabLine")

local spawntoy = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

local sintoys = workspace:FindFirstChild(lp.Name .. "SpawnedInToys")

local h = runs.Heartbeat
local render = runs.RenderStepped

module.pastas = {}
module.toys = {}
module.watching = {}

for _, folder in ipairs(workspace:GetChildren()) do
	if folder.Name:find("SpawnedInToys") then
		table.insert(module.pastas, folder)
	end
end

function fsearch(parent, name, timeout)
	if not parent or not name then return end
	local start = os.clock()
	timeout = timeout or 30

	while parent and parent.Parent and os.clock() - start < timeout do
		local found = parent:FindFirstChild(name)
		if found then return found end
		task.wait()
	end
end

function playerhavetoy(toy)
	local gui = lp:FindFirstChild("PlayerGui")
	local menu = gui and gui:FindFirstChild("MenuGui")
	local m = menu and menu:FindFirstChild("Menu")
	local tabs = m and m:FindFirstChild("TabContents")
	local toys = tabs and tabs:FindFirstChild("Toys")
	local contents = toys and toys:FindFirstChild("Contents")
	return contents and contents:FindFirstChild(toy)
end

function spawn(item, cframe, vector)
	if not item or not spawntoy then return end

	if not playerhavetoy(item) then
		local buy = rs:FindFirstChild("MenuToys") and rs.MenuToys:FindFirstChild("BuyToyRemoteFunction")
		if buy then buy:InvokeServer(item) end
	end

	spawntoy:InvokeServer(item, cframe, vector)
end

function rejoin()
	local tp = game:GetService("TeleportService")
	task.spawn(function()
		if lp then tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end
	end)
	while true do
		if lp then tp:Teleport(game.PlaceId, lp) end
		task.wait()
	end
end

function so(part, cframe)
	if not part or not part:IsA("BasePart") or not setowner then return end
	setowner:FireServer(part, cframe)
end

function createline(part, cframe)
	if not part or not cline then return end
	cline:FireServer(part, cframe)
end

function destroyline(part)
	if not part or not dline then return end
	dline:FireServer(part)
end

function module.watchFolder(folder)
	if not folder or module.watching[folder] then return end

	module.watching[folder] = {
		added = folder.ChildAdded:Connect(function(toy)
			local list = module.toys[toy.Name]
			if list then table.insert(list, toy) end
		end),

		removed = folder.ChildRemoved:Connect(function(toy)
			local list = module.toys[toy.Name]
			if not list then return end
			for i = #list, 1, -1 do
				if list[i] == toy then
					table.remove(list, i)
					break
				end
			end
		end)
	}

	for _, toy in ipairs(folder:GetChildren()) do
		local list = module.toys[toy.Name]
		if list then table.insert(list, toy) end
	end
end

workspace.ChildAdded:Connect(function(folder)
	if folder.Name:find("SpawnedInToys") then
		table.insert(module.pastas, folder)
		module.watchFolder(folder)
	end
end)

workspace.ChildRemoved:Connect(function(folder)
	local data = module.watching[folder]
	if not data then return end

	data.added:Disconnect()
	data.removed:Disconnect()
	module.watching[folder] = nil

	for _, list in pairs(module.toys) do
		for i = #list, 1, -1 do
			if not list[i] or not list[i].Parent then
				table.remove(list, i)
			end
		end
	end
end)

for _, folder in ipairs(module.pastas) do
	module.watchFolder(folder)
end

function module.gettoys(name)
	if not name then return {} end

	if not module.toys[name] then
		module.toys[name] = {}
		for _, folder in ipairs(module.pastas) do
			for _, toy in ipairs(folder:GetChildren()) do
				if toy.Name == name then
					table.insert(module.toys[name], toy)
				end
			end
		end
	end

	return module.toys[name]
end

return module
