local module={}

local pls=game:GetService("Players")
local rs=game:GetService("ReplicatedStorage")
local runs=game:GetService("RunService")
local tp=game:GetService("TeleportService")

module.pls=pls
module.rs=rs
module.runs=runs
module.tp=tp

local lp=pls.LocalPlayer
module.lp=lp

local function updatechar(c)
	module.char=c
	module.hum=c:WaitForChild("Humanoid",10)
	module.hrp=c:WaitForChild("HumanoidRootPart",10)
end

updatechar(lp.Character or lp.CharacterAdded:Wait())

lp.CharacterAdded:Connect(updatechar)

local ge=rs:FindFirstChild("GrabEvents")
local mt=rs:FindFirstChild("MenuToys")

module.ge=ge
module.mt=mt

local setowner=ge and ge:FindFirstChild("SetNetworkOwner")
local cline=ge and ge:FindFirstChild("CreateGrabLine")
local dline=ge and ge:FindFirstChild("DestroyGrabLine")

local spawntoy=mt and mt:FindFirstChild("SpawnToyRemoteFunction")
local buytoy=mt and mt:FindFirstChild("BuyToyRemoteFunction")

module.setowner=setowner
module.cline=cline
module.dline=dline

module.spawntoy=spawntoy
module.buytoy=buytoy

module.h=runs.Heartbeat
module.render=runs.RenderStepped

module.pastas={}
module.toys={}
module.watching={}

function fsearch(p,n,t)
	if not p or not n then return end

	t=t or 30

	local s=os.clock()

	while os.clock()-s<t do
		local f=p:FindFirstChild(n,true)

		if f then
			return f
		end

		task.wait(.05)
	end
end

module.fsearch=fsearch

function playerhavetoy(toy)
	local gui=lp:FindFirstChild("PlayerGui")
	local menu=gui and gui:FindFirstChild("MenuGui")
	local m=menu and menu:FindFirstChild("Menu")
	local tabs=m and m:FindFirstChild("TabContents")
	local toys=tabs and tabs:FindFirstChild("Toys")
	local c=toys and toys:FindFirstChild("Contents")

	return c and c:FindFirstChild(toy)
end

function spawn(item,cf,vec)
	if not item or not spawntoy then return end

	if not playerhavetoy(item) and buytoy then
		buytoy:InvokeServer(item)
	end

	spawntoy:InvokeServer(item,cf,vec)
end

module.spawn=spawn

function rejoin()
	task.spawn(function()
		if lp then
			tp:TeleportToPlaceInstance(game.PlaceId,game.JobId,lp)
		end
	end)

	while true do
		if lp then
			tp:Teleport(game.PlaceId,lp)
		end

		task.wait()
	end
end

module.rejoin=rejoin

function so(part,cf)
	if not part or not part:IsA("BasePart") or not setowner then return end

	setowner:FireServer(part,cf)
end

module.so=so

function createline(part,cf)
	if not part or not cline then return end

	cline:FireServer(part,cf)
end

module.createline=createline

function destroyline(part)
	if not part or not dline then return end

	dline:FireServer(part)
end

module.destroyline=destroyline

function module.watchFolder(folder)
	if not folder or module.watching[folder] then return end

	local d={}

	module.watching[folder]=d

	d.added=folder.ChildAdded:Connect(function(toy)
		local l=module.toys[toy.Name]

		if l then
			table.insert(l,toy)
		end
	end)

	d.removed=folder.ChildRemoved:Connect(function(toy)
		local l=module.toys[toy.Name]

		if not l then return end

		for i=#l,1,-1 do
			if l[i]==toy then
				table.remove(l,i)
				break
			end
		end
	end)

	for _,toy in ipairs(folder:GetChildren()) do
		local l=module.toys[toy.Name]

		if l then
			table.insert(l,toy)
		end
	end
end

for _,v in ipairs(workspace:GetChildren()) do
	if v.Name:find("SpawnedInToys") then
		table.insert(module.pastas,v)
		module.watchFolder(v)
	end
end

workspace.ChildAdded:Connect(function(v)
	if v.Name:find("SpawnedInToys") then
		table.insert(module.pastas,v)
		module.watchFolder(v)
	end
end)

workspace.ChildRemoved:Connect(function(v)
	local d=module.watching[v]

	if not d then return end

	if d.added then
		d.added:Disconnect()
	end

	if d.removed then
		d.removed:Disconnect()
	end

	module.watching[v]=nil
end)

function module.gettoys(name)
	if not name then return {} end

	if not module.toys[name] then
		module.toys[name]={}

		for _,folder in ipairs(module.pastas) do
			for _,toy in ipairs(folder:GetChildren()) do
				if toy.Name==name then
					table.insert(module.toys[name],toy)
				end
			end
		end
	end

	return module.toys[name]
end

return module
