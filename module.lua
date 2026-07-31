local module = {}

local pls = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local runs = game:GetService("RunService")
local tp = game:GetService("TeleportService")

module.pls = pls
module.rs = rs
module.runs = runs
module.tp = tp

local lp = pls.LocalPlayer
module.lp = lp

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
local mt = rs:FindFirstChild("MenuToys")

local setowner = ge and ge:FindFirstChild("SetNetworkOwner")
local cline = ge and ge:FindFirstChild("CreateGrabLine")
local dline = ge and ge:FindFirstChild("DestroyGrabLine")

local spawntoy = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
local buytoy = mt and mt:FindFirstChild("BuyToyRemoteFunction")

module.ge = ge
module.mt = mt

module.setowner = setowner
module.cline = cline
module.dline = dline

module.spawntoy = spawntoy
module.buytoy = buytoy

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

function fsearch(p,n,t)
	if not p or not n then return end

	t=t or 30

	local s=os.clock()

	repeat
		local f=p:FindFirstChild(n)

		if f then
			return f
		end

		task.wait()
	until os.clock()-s>=t
end

module.fsearch=fsearch
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

	local data = {}

	module.watching[folder] = data

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
