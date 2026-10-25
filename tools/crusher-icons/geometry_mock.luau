-- Headless geometry harness only: not a Roblox rendering/physics substitute.
local vm = {}
local Vector3 = {}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end
function vm.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vm.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vm.__unm(a) return a*-1 end
function vm.__mul(a,b) if type(a)=='number' then a,b=b,a end return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function vm.__div(a,b) return a*(1/b) end
function vm.__index(a,k)
 if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
 if k=='Unit' then return a/a.Magnitude end
 if k=='Dot' then return function(x,y) return x.X*y.X+x.Y*y.Y+x.Z*y.Z end end
 if k=='Cross' then return function(x,y) return Vector3.new(x.Y*y.Z-x.Z*y.Y,x.Z*y.X-x.X*y.Z,x.X*y.Y-x.Y*y.X) end end
end
local cm={};cm.__index=cm
local Color3={new=function(r,g,b) return setmetatable({R=r,G=g,B=b},cm) end}
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
function cm:Lerp(b,f) return Color3.new(self.R+(b.R-self.R)*f,self.G+(b.G-self.G)*f,self.B+(b.B-self.B)*f) end
local CFrame={};local fm={}
local function cf(p,r) return setmetatable({Position=p,R=r},fm) end
local function ident() return {1,0,0,0,1,0,0,0,1} end
function CFrame.new(x,y,z) return cf(if type(x)=='table' then x else Vector3.new(x,y,z),ident()) end
local function rotate(r,v) return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z) end
function fm.__mul(a,b)
 if b.X then return a.Position+rotate(a.R,b) end
 local r={};for i=0,2 do for j=0,2 do local v=0;for k=0,2 do v+=a.R[i*3+k+1]*b.R[k*3+j+1] end;r[i*3+j+1]=v end end
 return cf(a.Position+rotate(a.R,b.Position),r)
end
function CFrame.Angles(x,y,z)
 local a,b,c,d,e,f=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 return cf(Vector3.new(),{1,0,0,0,a,-b,0,b,a})*cf(Vector3.new(),{c,0,d,0,1,0,-d,0,c})*cf(Vector3.new(),{e,-f,0,f,e,0,0,0,1})
end
function CFrame.lookAt(p,q)
 local forward=(q-p).Unit;local up=Vector3.new(0,1,0)
 if math.abs(forward:Dot(up))>0.99 then up=Vector3.new(0,0,1) end
 local right=forward:Cross(up).Unit;up=right:Cross(forward)
 return cf(p,{right.X,up.X,-forward.X,right.Y,up.Y,-forward.Y,right.Z,up.Z,-forward.Z})
end
function fm.__index(a,k)
 if k=='PointToObjectSpace' then return function(self,v) local d=v-self.Position;local r=self.R;return rotate({r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]},d) end end
end
local Enum=setmetatable({}, {__index=function(t,k) local g=setmetatable({}, {__index=function(s,n) local v=k..'.'..n;rawset(s,n,v);return v end});rawset(t,k,g);return g end})
local UDim2={fromScale=function(x,y) return {x,y} end}
local methods={};local im={}
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants() local all={};for _,c in self.children do table.insert(all,c);for _,d in c:GetDescendants() do table.insert(all,d) end end;return all end
function methods:IsA(n) return self.ClassName==n or n=='Instance' or (n=='BasePart' and self.ClassName=='Part') end
function methods:FindFirstChild(n) for _,c in self.children do if c.Name==n then return c end end;return nil end
function methods:FindFirstChildOfClass(n) for _,c in self.children do if c.ClassName==n then return c end end;return nil end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:Destroy() for _,c in self:GetChildren() do c:Destroy() end;self.Parent=nil end
function im.__index(o,k) if methods[k] then return methods[k] end;if o.props[k]~=nil then return o.props[k] end;return o:FindFirstChild(k) end
function im.__newindex(o,k,v)
 if k=='Parent' then local prev=o.props.Parent;if prev then local n=table.find(prev.children,o);if n then table.remove(prev.children,n) end end;if v then table.insert(v.children,o) end end
 o.props[k]=v
end
local Instance={new=function(class) return setmetatable({props={ClassName=class,Name=class,Anchored=false,CanCollide=true,CanTouch=true,CanQuery=true,CastShadow=true,Transparency=0,Shape='PartType.Block'},children={},attrs={}},im) end}
local task={wait=function() end}
local services={};for _,n in {'Workspace','ReplicatedStorage','Lighting','CollectionService','TweenService'} do services[n]=Instance.new(n) end
local game={GetService=function(_,n) assert(services[n],n);return services[n] end}
local function named(parent,name) local o=Instance.new('Folder');o.Name=name;o.Parent=parent;return o end
local shared=named(services.ReplicatedStorage,'Shared');local sharedKit=named(shared,'Kit')
local server=Instance.new('Folder');local serverKit=named(server,'Kit')
for _,n in {'Config'} do named(shared,n) end
named(sharedKit,'Style')
for _,n in {'Build','FactoryProps'} do named(serverKit,n) end
named(server,'World')
local modules={}
local function require(m) assert(m and modules[m.Name],'missing module');return modules[m.Name] end
Vector3.zero=Vector3.new()
local Vector2={new=function(x,y) return {X=x,Y=y} end}
function CFrame.fromMatrix(p,x,y,z) return cf(p,{x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z}) end
local priorIsA=methods.IsA
function methods:IsA(n) return priorIsA(self,n) or (n=='BasePart' and self.ClassName=='WedgePart') end
function methods:GetPivot() return self.WorldPivot or CFrame.new() end
function methods:GetBoundingBox()
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in self:GetDescendants() do if p:IsA('BasePart') then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=p.CFrame*Vector3.new(p.Size.X*x/2,p.Size.Y*y/2,p.Size.Z*z/2)
   lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
   hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
  end end end
 end end
 return CFrame.new((lo+hi)/2),hi-lo
end
function methods:ScaleTo(scale)
 local ratio=scale/(self._scale or 1)
 for _,p in self:GetDescendants() do if p:IsA('BasePart') then
  p.Size=p.Size*ratio;p.CFrame=cf(p.CFrame.Position*ratio,p.CFrame.R)
 elseif p:IsA('Model') and p.WorldPivot then p.WorldPivot=cf(p.WorldPivot.Position*ratio,p.WorldPivot.R) end end
 self._scale=scale
end
function methods:PivotTo(at) assert(at.Position.Magnitude<.0001) end
function services.CollectionService:AddTag() end
