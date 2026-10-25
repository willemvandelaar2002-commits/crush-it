-- Command Bar, EDIT mode. Creates only disposable copies of actual imports.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play first')
local RS=game:GetService('ReplicatedStorage')
assert(not workspace:FindFirstChild('CrusherIconExport'),'Inspect/remove the previous export folder first')
require(game:GetService('ServerScriptService').Server.CrusherPreviews).start()
local sources={}
for _,id in {'TwinTitan','RocketPress','Magnetron','GoldenKing','Toyzilla'} do
 local m=RS.CrusherPreviewModels:FindFirstChild(id)
 assert(m and m:GetAttribute('ImportedSpecial'),id..' is missing its actual imported template')
 table.insert(sources,m)
end
local folder=Instance.new('Folder');folder.Name='CrusherIconExport';folder.Parent=workspace
for _,m in sources do m:Clone().Parent=folder end
game:GetService('Selection'):Set({folder:GetChildren()[1]})
print('Export ONE named model at a time as <TypeId>.obj; retain MTL/textures. Send the exports or original FBX pack to finish the five icons. Delete only CrusherIconExport afterwards. ServerStorage originals are unchanged.')
