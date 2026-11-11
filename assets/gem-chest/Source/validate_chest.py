import bpy,bmesh,json,pathlib,math
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
R=pathlib.Path(__file__).resolve().parent;O=R.parent if R.name=='Source' else R/'CrushIt-Gem-Chest'
d=json.loads((O/'Model-manifest.json').read_text());checks=[]
bpy.ops.wm.open_mainfile(filepath=str(O/'Blender'/'GemChest.blend'))
names=['ChestBody','ChestLid','ChestGlow','LidGlow']
assert d['triangles']<=3000
objects=[bpy.data.objects[n] for n in names]
for o in objects:
    o.data.calc_loop_triangles();assert len(o.data.uv_layers)==1
    bm=bmesh.new();bm.from_mesh(o.data);be=sum(e.is_boundary for e in bm.edges);non=sum(not e.is_manifold for e in bm.edges);bm.free()
    assert be==0 and non==0,(o.name,be,non)
    assert all(len(p.vertices)==3 for p in o.data.polygons)
    checks.append({'part':o.name,'triangles':len(o.data.loop_triangles),'openBoundaryEdges':be,'nonManifoldEdges':non,'UV':True})
for n in ['ChestLid','LidGlow']:
    assert (bpy.data.objects[n].location-Vector(d['hingeBlender'])).length<1e-5
checks.append({'commonLidPivotPassed':True,'sourceHinge':d['hingeBlender']})

# Sample the empty upper well with the lid omitted: no solid top filler.
body=bpy.data.objects['ChestBody'];verts=[body.matrix_world@v.co for v in body.data.vertices];faces=[tuple(p.vertices) for p in body.data.polygons]
bv=BVHTree.FromPolygons(verts,faces,all_triangles=True);samples=0
for ix in range(-5,6):
    for iy in range(-4,5):
        hit=bv.ray_cast(Vector((ix*.4,iy*.35,4.17)),Vector((0,0,-1)),1.30)
        assert hit[0] is None,(ix,iy,hit[0]);samples+=1
checks.append({'upperInteriorRaySamplesPassed':samples,'emptyUpperWell':True})

# Verify authored positive-X opening actually lifts the front and both moving
# meshes use an identical transform, without modifying any gameplay script.
hinge=Vector(d['hingeBlender']);front=Vector((0,2.73,4.33))
heights=[]
for degrees in [0,25,50,75,100]:
    opened=hinge+Matrix.Rotation(math.radians(degrees),3,'X')@(front-hinge)
    assert opened.z>=front.z-1e-5
    heights.append([degrees,round(opened.z,5)])
checks.append({'positiveXOpeningLiftsFront':True,'frontHeightByDegrees':heights,'notFullCollisionSweep':'Attached decorative hinge barrels intentionally meet the rear wall. Studio clearance check still required.'})

# Round-trip the actual delivery files, count parts/triangles, check pivots.
for kind,relative in [('FBX','FBX/GemChest.fbx'),('GLB','GLB/GemChest.glb')]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if kind=='FBX':bpy.ops.import_scene.fbx(filepath=str(O/relative))
    else:bpy.ops.import_scene.gltf(filepath=str(O/relative))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert sorted(o.name for o in meshes)==sorted(names)
    total=0
    for o in meshes:
        o.data.calc_loop_triangles();total+=len(o.data.loop_triangles)
        assert len(o.data.uv_layers)>0 and len(o.data.materials)>0
    assert total==d['triangles'],(kind,total,d['triangles'])
    # Importers may place transforms on a parent; compare full world origins.
    a=bpy.data.objects['ChestLid'].matrix_world.translation
    b=bpy.data.objects['LidGlow'].matrix_world.translation
    assert (a-b).length<1e-5
    checks.append({'format':kind,'reimportPassed':True,'meshCount':len(meshes),'triangles':total,'lidOriginsMatch':True,'UVsAndMaterials':True})

(O/'Validation.json').write_text(json.dumps({'allPassed':True,'scope':'Blender geometry/export validation; no Roblox Studio runtime or interaction test.','checks':checks},indent=2)+'\n')
print('ALL_CHEST_VALIDATION_PASSED',flush=True)
