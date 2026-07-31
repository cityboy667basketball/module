local module = {}

local pls = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local runs = game:GetService("RunService")
local tp = game:GetService("TeleportService")

local lp = pls.LocalPlayer

local function updatechar(c)
	local h = c:WaitForChild("Humanoid", 10)
	local r = c:WaitForChild("HumanoidRootPart", 10)

	module.char = c
	module.hum = h
	module.hrp = r
end

local char = lp.Character or lp.CharacterAdded:Wait()
updatechar(char)

lp.CharacterAdded:Connect(updatechar)

module.char = char
module.hrp = char:FindFirstChild("HumanoidRootPart")
module.hum = char:FindFirstChild("Humanoid")

local ge = rs:FindFirstChild("GrabEvents")
local ce = rs.CharacterEvents
local mt = rs:FindFirstChild("MenuToys")


local setowner = ge and ge:FindFirstChild("SetNetworkOwner")
local cline = ge and ge:FindFirstChild("CreateGrabLine")
local dline = ge and ge:FindFirstChild("DestroyGrabLine")

local spawntoy = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
local buytoy = mt and mt:FindFirstChild("BuyToyRemoteFunction")

local h = runs.Heartbeat
local render = runs.RenderStepped

module.h = h
module.render = render

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

	while parent.Parent and os.clock() - start < timeout do
		local found = parent:FindFirstChild(name)
		if found then
			return found
		end

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

	if not playerhavetoy(item) and buytoy then
		buytoy:InvokeServer(item)
	end

	spawntoy:InvokeServer(item, cframe, vector)
end

function rejoin()
	local tp = game:GetService("TeleportService")

	task.spawn(function()
		if lp then
			tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
		end
	end)

	while true do
		if lp then
			tp:Teleport(game.PlaceId, lp)
		end
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

	module.watching[folder] = {}

	local data = module.watching[folder]

	data.added = folder.ChildAdded:Connect(function(toy)
		local list = module.toys[toy.Name]

		if list then
			table.insert(list, toy)
		end
	end)

	data.removed = folder.ChildRemoved:Connect(function(toy)
		local list = module.toys[toy.Name]

		if not list then return end

		for i = #list, 1, -1 do
			if list[i] == toy then
				table.remove(list, i)
				break
			end
		end
	end)

	for _, toy in ipairs(folder:GetChildren()) do
		local list = module.toys[toy.Name]

		if list then
			table.insert(list, toy)
		end
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

	if data.added then
		data.added:Disconnect()
	end

	if data.removed then
		data.removed:Disconnect()
	end

	module.watching[folder] = nil
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
