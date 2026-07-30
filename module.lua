local module = {}


--var normal
local pls = game:GetService("Players")
local lp = pls.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local rf = game:GetService("ReplicatedFirst")
local runs = game:GetService("RunService")
local light = game:GetService("Lighting")
local char = lp.Character
local hrp = char.WaitForChild("HumanoidRootPart", 3)
local hum = char.WaitForChild("Humanoid", 3)

--var ftap

local ce = rs.CharacterEvents 
local ge = rs.GrabEvents 

local setowner = ge.SetNetworkOwner
local cline = ge.CreateGrabLine
local dline = ge.DestroyGrabLine

local spawntoy = game:GetService("ReplicatedStorage").MenuToys.SpawnToyRemoteFunction

local sintoys = workspace[lp.Name .. "SpawnedInToys"]


--var RunService
local h = runs.Heartbeat
local render = runs.RenderStepped

--var toys

module.pastas = {}
module.toys = {}
module.watching = {}

for _, folder in ipairs(workspace:GetChildren()) do
	if folder.Name:find("SpawnedInToys") then
		table.insert(module.pastas, folder)
	end
end



--functions

function fsearch(parent, name, timeout)
	local start = os.clock()
	timeout = timeout or 30

	while os.clock() - start < timeout do
		if not parent or not parent.Parent then return end

		local found = parent:FindFirstChild(name)
		if found then return found end

		task.wait()
	end
end


function playerhavetoy(toy)
	local gui = lp:FindFirstChild("PlayerGui")
	if not gui then return end

	local menu = gui:FindFirstChild("MenuGui")
	if not menu then return end

	local m = menu:FindFirstChild("Menu")
	if not m then return end

	local tabs = m:FindFirstChild("TabContents")
	if not tabs then return end

	local toys = tabs:FindFirstChild("Toys")
	if not toys then return end

	local contents = toys:FindFirstChild("Contents")
	if not contents then return end

	return contents:FindFirstChild(toy)
end





function spawn(item, cframe, vector)
	if not item then return end

	if not playerhavetoy(item) then
		rs.MenuToys.BuyToyRemoteFunction:InvokeServer(item)
	end
    
	spawntoy:InvokeServer(item, cframe, vector)
end


function rejoin()
	task.spawn(function()game.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)end)
	repeat
		game.TeleportService:Teleport(game.PlaceId, lp)
		task.wait()
	until false
end





function so(part, cframe)
    if not part and not part:IsA("BasePart") then return end
    setowner:FireServer(part, cframe)
end

function createline(part, cframe)
    if not part then return end
    cline:FireServer(part, cframe)
end

function destroyline(part)
    if not part then return end
    dline:FireServer(part)
end





function module.watchFolder(folder)
	if module.watching[folder] then return end

	module.watching[folder] = {
		added = folder.ChildAdded:Connect(function(toy)
			local list = module.toys[toy.Name]
			if list then
				table.insert(list, toy)
			end
		end),

		removed = folder.ChildRemoved:Connect(function(toy)
			local list = module.toys[toy.Name]
			if not list then return end

			for i, v in ipairs(list) do
				if v == toy then
					table.remove(list, i)
					break
				end
			end
		end)
	}

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

	data.added:Disconnect()
	data.removed:Disconnect()

	module.watching[folder] = nil

	for _, list in pairs(module.toys) do
		for i = #list, 1, -1 do
			if not list[i].Parent then
				table.remove(list, i)
			end
		end
	end
end)


for _, folder in ipairs(module.pastas) do
	module.watchFolder(folder)
end


function module.gettoys(name)
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
