"""Run the actual pure Luau economy/rules modules under the Luau CLI.
Small datatype/service adapters are used; this is not a Studio integration test.
"""
from pathlib import Path
import re,subprocess,sys,json
root=Path(__file__).resolve().parents[2]
exe=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else root.parent/'luau-tools/luau'
header="""
local Enum=setmetatable({}, {__index=function(t,k) local e=setmetatable({}, {__index=function(_,v) return k.."."..v end}) rawset(t,k,e) return e end})
local V={}
local mt={}
function mt.__add(a,b) return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function mt.__sub(a,b) return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function mt.__mul(a,b) if type(a)=="number" then a,b=b,a end return V.new(a.X*b,a.Y*b,a.Z*b) end
function mt.__div(a,b) return V.new(a.X/b,a.Y/b,a.Z/b) end
function mt.__unm(a) return V.new(-a.X,-a.Y,-a.Z) end
function mt.__index(a,k)
 if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
 if k=="Unit" then return a/a.Magnitude end
 if k=="Dot" then return function(x,y) return x.X*y.X+x.Y*y.Y+x.Z*y.Z end end
end
function V.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},mt) end
local Vector3=V
V.zero=V.new() V.one=V.new(1,1,1) V.xAxis=V.new(1,0,0) V.yAxis=V.new(0,1,0) V.zAxis=V.new(0,0,1)
local Vector2={new=function(x,y) return V.new(x,y,0) end,zero=V.zero}
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local function copy(v)
 if type(v)~="table" then return v end
 local t={} for k,x in v do t[k]=copy(x) end return t
end
-- Fixtures only need a detached table roundtrip; actual Roblox JSON is a Studio check.
local game={ReplicatedStorage={Shared={}},HttpService={JSONEncode=function(self,v) return copy(v) end,JSONDecode=function(self,v) return copy(v) end},GetService=function(self,name)
 if name=="RunService" then return {IsStudio=function() return false end} end
 error("Unexpected service "..name)
end}
local cache={}
local modules={}
local function loadModule(name)
 if cache[name] then return cache[name] end
 assert(modules[name],"Missing module "..name)
 local m=modules[name]() cache[name]=m return m
end
"""
sources={}
def add(name):
 if name in sources:return
 file=root/'src/shared'/(name+'.luau')
 if not file.exists():file=root/'src/server/Tests'/(name+'.luau')
 text=file.read_text()
 sources[name]=''
 def req(m):
  other=m[1].split('.')[-1]
  add(other)
  return 'loadModule('+json.dumps(other)+')'
 text=re.sub(r'require\(([^)]+)\)',req,text)
 sources[name]='modules['+json.dumps(name)+']=function()\n'+text+'\nend\n'
tests=['CrusherRules.spec','CrusherRows.spec','CrusherRollPresentation.spec','AutoRoll.spec']
# Only explicitly present pure fixtures are run.
tests=[t for t in tests if (root/'src/server/Tests'/(t+'.luau')).exists()]
for name in tests:add(name)
for name in ['ExoticCrusherAssets','FactoryEventConfig']:add(name)
extra="""
local C=loadModule("CrusherConfig")
local R=loadModule("CrusherRules")
local Rows=loadModule("CrusherRows")
local Assets=loadModule("ExoticCrusherAssets")
local count=0
local function check(v,msg) assert(v,msg) count+=1 end
local ex=C.rarity("Exotic")
check(#ex.types==6,"Six permanent Exotic crushers")
check(C.rarity("Legendary").rank<ex.rank and ex.rank<C.rarity("Secret").rank,"Rank ordering")
local sum=0 for _,r in C.Rarities do sum+=r.weight end
check(math.abs(sum-100)<1e-10,"Probability mass stays 100")
local ids={} local serial=0
local function guid() serial+=1 return "exotic-"..serial end
for _,id in ex.types do
 check(not ids[id],"Unique ID") ids[id]=true
 check(C.oddsFor(id)==15000,"Per-type base odds")
 check(C.effectiveOdds(id,20,2,.1,false)<C.effectiveOdds(id,0,1,0,false),"Luck helps Exotic")
 check(not C.typeById(id).crate and not C.typeById(id).event,"Permanent pool")
 check(Assets[id] and #Assets[id].motion>0,"Rig metadata")
 local d=R.migrate({cash=1e9},guid) d.crushers.rolls=1
 local weights=C.rollWeights(0,1,0,false) local before=0
 for i,r in C.Rarities do if r==ex then break end before+=weights[i] end
 -- Choose each of the six entries through the real Roll transaction.
 local ix=table.find(ex.types,id)
 local draws={(before+ex.weight/2)/100, .1,(ix-.5)/#ex.types};local at=0
 local state={}
 local ok,_,offers=R.act(d,state,"Roll",{},0,function() at+=1 return draws[at] or .1 end,guid,{})
 check(ok and offers[1].type==id and offers[1].rarity=="Exotic","Reachable server roll "..id)
 local bought,_,item=R.act(d,state,"Buy",{slot=1},state.nextRoll,math.random,guid,{})
 check(bought and item.type==id,"Buy "..id)
 local again=R.migrate(d,guid)
 check(R.find(again,item.id)~=nil,"Save migration retains "..id)
end
local d=R.migrate({cash=1e9},guid)
d.crushers.owned={} d.crushers.equipped={} d.crushers.bays=C.MaxBays d.crushers.plotLevel=C.PlotUpgrade.MaxLevel
for i,id in ex.types do
 local item={id=guid(),type=id,rarity="Exotic",modifier="Standard",level=1}
 table.insert(d.crushers.owned,item) d.crushers.equipped[tostring(i)]=item.id
end
local row=Rows.snapshot(d).rows[1]
check(row.active and row.rarity=="Exotic" and row.bonus==.44,"Full Exotic row")
d.crushers.equipped["6"]=nil
check(not Rows.snapshot(d).rows[1].active,"Broken Exotic row")
check(loadModule("FactoryEventConfig").Points.Exotic==5.5,"Event points")
local function output(r) return C.typeById(C.rarity(r).types[1]).value*C.rarity(r).mult end
check(output("Legendary")<output("Exotic") and output("Exotic")<output("Secret"),"Output ordering")
check(table.find(C.AutoRoll.Rarities,"Exotic")~=nil,"Autoroller knows Exotic")
print("EXOTIC",count,"assertions passed")
"""
out=header+'\n'.join(sources.values())+'\n'+''.join('print('+json.dumps(t)+',loadModule('+json.dumps(t)+')().passed)\n' for t in tests)+extra
temp=root/'tools/exotic/.bundled-tests.luau'
temp.write_text(out)
try:subprocess.run([str(exe),str(temp)],check=True)
finally:temp.unlink(missing_ok=True)
