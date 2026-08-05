local mod = {}

local pls = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local runs = game:GetService("RunService")
local tp = game:GetService("TeleportService")

local lp = pls.LocalPlayer
local sintoys = workspace:FindFirstChild(lp.Name .. "SpawnedInToys")

local ge = rs:FindFirstChild("GrabEvents")
local mt = rs:FindFirstChild("MenuToys")

local setowner = ge and ge:FindFirstChild("SetNetworkOwner")
local cline = ge and ge:FindFirstChild("CreateGrabLine")
local dline = ge and ge:FindFirstChild("DestroyGrabLine")

local spawntoy = mt and mt:FindFirstChild("SpawnToyRemoteFunction")
local buytoy = mt and mt:FindFirstChild("BuyToyRemoteFunction")

local stats = game:GetService("Stats")
local dataPing = stats.Network.ServerStatsItem["Data Ping"]

local ema = 0
local samples = {}
local sum = 0
local maxSamples = 10


local function updatechar(c)
	mod.char = c
	mod.hum = c:WaitForChild("Humanoid", 10)
	mod.hrp = c:WaitForChild("HumanoidRootPart", 10)
end

updatechar(lp.Character or lp.CharacterAdded:Wait())

lp.CharacterAdded:Connect(updatechar)


function fsearch(p, n, t)
	if not p or not n then return end

	t = t or 30

	local s = os.clock()

	while os.clock() - s < t do
		local f = p:FindFirstChild(n, true)

		if f then
			return f
		end

		task.wait(.05)
	end
end


function playerhavetoy(toy)
	local gui = lp:FindFirstChild("PlayerGui")
	local menu = gui and gui:FindFirstChild("MenuGui")
	local m = menu and menu:FindFirstChild("Menu")
	local tabs = m and m:FindFirstChild("TabContents")
	local toys = tabs and tabs:FindFirstChild("Toys")
	local c = toys and toys:FindFirstChild("Contents")

	return c and c:FindFirstChild(toy)
end


function spawn(item, cf, vec)
	if not item or not spawntoy then return end

	if not playerhavetoy(item) and buytoy then
		buytoy:InvokeServer(item)
	end

	spawntoy:InvokeServer(item, cf, vec)
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


function so(part, cf)
	if not part or not part:IsA("BasePart") or not setowner then return end

	setowner:FireServer(part, cf)
end


function createline(part, cf)
	if not part or not cline then return end

	cline:FireServer(part, cf)
end


function destroyline(part)
	if not part or not dline then return end

	dline:FireServer(part)
end


function mod.watchFolder(folder)
	if not folder or mod.watching[folder] then return end

	local d = {}

	mod.watching[folder] = d

	d.added = folder.ChildAdded:Connect(function(toy)
		local l = mod.toys[toy.Name]

		if l then
			table.insert(l, toy)
		end
	end)

	d.removed = folder.ChildRemoved:Connect(function(toy)
		local l = mod.toys[toy.Name]

		if not l then return end

		for i = #l, 1, -1 do
			if l[i] == toy then
				table.remove(l, i)
				break
			end
		end
	end)

	for _, toy in ipairs(folder:GetChildren()) do
		local l = mod.toys[toy.Name]

		if l then
			table.insert(l, toy)
		end
	end
end


for _, v in ipairs(workspace:GetChildren()) do
	if v.Name:find("SpawnedInToys") then
		table.insert(mod.pastas, v)
		mod.watchFolder(v)
	end
end


workspace.ChildAdded:Connect(function(v)
	if v.Name:find("SpawnedInToys") then
		table.insert(mod.pastas, v)
		mod.watchFolder(v)
	end
end)


workspace.ChildRemoved:Connect(function(v)
	local d = mod.watching[v]

	if not d then return end

	if d.added then
		d.added:Disconnect()
	end

	if d.removed then
		d.removed:Disconnect()
	end

	mod.watching[v] = nil
end)


function mod.gettoys(name)
	if not name then return {} end

	if not mod.toys[name] then
		mod.toys[name] = {}

		for _, folder in ipairs(mod.pastas) do
			for _, toy in ipairs(folder:GetChildren()) do
				if toy.Name == name then
					table.insert(mod.toys[name], toy)
				end
			end
		end
	end

	return mod.toys[name]
end


function mod.getping()
	local value = dataPing and dataPing:GetValue()

	if value and value > 0 then
		samples[#samples + 1] = value
		sum += value

		if #samples > maxSamples then
			sum -= table.remove(samples, 1)
		end

		local average = sum / #samples

		ema = ema ~= 0 and (ema + (average - ema)) or average

		return math.floor(ema)
	end

	return 0
end


-- Exports

mod.pls = pls
mod.rs = rs
mod.runs = runs
mod.tp = tp

mod.lp = lp
mod.sintoys = sintoys

mod.ge = ge
mod.mt = mt

mod.setowner = setowner
mod.cline = cline
mod.dline = dline

mod.spawntoy = spawntoy
mod.buytoy = buytoy

mod.h = runs.Heartbeat
mod.render = runs.RenderStepped

mod.pastas = {}
mod.toys = {}
mod.watching = {}

mod.fsearch = fsearch
mod.spawn = spawn
mod.rejoin = rejoin
mod.so = so
mod.createline = createline
mod.destroyline = destroyline


return mod
