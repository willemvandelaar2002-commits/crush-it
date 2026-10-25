-- Read-only Command Bar check after importing the PNGs into this experience.
local RS=game:GetService('ReplicatedStorage');local I=require(RS.Shared.CrusherIcons)
local good,bad,pending=0,0,0
for _,def in require(RS.Shared.CrusherConfig).Types do
 local uri=I.image(def.id)
 if not uri then pending+=1;print('NEEDS SPECIAL MODEL EXPORT',def.id);continue end
 local loaded=false
 local probe=Instance.new('ImageLabel');probe.Image=uri
 local ok=pcall(function() game:GetService('ContentProvider'):PreloadAsync({probe},function(_,s) loaded=s==Enum.AssetFetchStatus.Success end) end)
 probe:Destroy()
 if ok and loaded then good+=1 else bad+=1;warn('ICON NOT READY',def.id,uri) end
end
print(good,'loaded',bad,'uploads not ready',pending,'special exports pending')
