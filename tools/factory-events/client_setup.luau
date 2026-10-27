
-- Run the actual LocalScript with UI signals/camera surfaces, not a Studio UI render.
services.Players.LocalPlayer=b
local pg=Instance.new('PlayerGui') pg.Name='PlayerGui' pg.Parent=b
b.CharacterRemoving=signal()
services.SoundService=Instance.new('SoundService') services.ContentProvider=Instance.new('ContentProvider')
function services.ContentProvider:PreloadAsync(sounds) for _,s in sounds do s.IsLoaded=true end end
services.RunService.RenderStepped=signal()
local UDim={new=function(...) return {...} end}
function UDim2.new(...) return {...} end
function UDim2.fromOffset(...) return {...} end
function methods:WaitForChild(n) return assert(self:FindFirstChild(n),'mock missing '..n) end
function methods:Play() self.IsPlaying=true end
function methods:Stop() self.IsPlaying=false end
local instancePrior=Instance.new
function Instance.new(class)
	local o=instancePrior(class)
	if class=='TextButton' then o.Activated=signal() end
	return o
end
local calls={}
modules.Net.event('Travel')
modules.Net.event('PlotUpgraded')
for _,r in remotes do
	r.OnClientEvent=signal()
	function r:FireServer(...) table.insert(calls,{...}) end
end
-- The real Style helpers have their own existing tests; this harness checks
-- our UI's state/actions and camera lifecycle, not UIStroke rendering.
modules.Style={panel=function() end,text=function() end,button=function() end,setButtonColor=function() end}
local camera=Instance.new('Camera') camera.CameraType=Enum.CameraType.Custom
camera.FieldOfView=72 camera.CameraSubject=b.Character:FindFirstChildOfClass('Humanoid')
camera.CFrame=CFrame.new(0,20,70) workspace.CurrentCamera=camera
local clientScript=Instance.new('LocalScript') clientScript.Name='FactoryEvent'
clientScript.Parent=shared clientScript.Destroying=signal()
local savedCamera=camera.CFrame
