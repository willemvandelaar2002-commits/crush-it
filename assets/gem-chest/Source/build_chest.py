import bpy, bmesh, math, pathlib, json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent;O=R.parent if R.name=='Source' else R/'CrushIt-Gem-Chest'
for n in ['FBX','Blender','Textures','Previews','Source']:(O/n).mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
P=[('Navy',(25,31,64),.3,.34),('NavyLight',(46,53,91),.3,.32),('Gold',(255,196,40),.45,.28),('GoldLight',(255,231,132),.35,.27),('Magenta',(232,48,205),.12,.24),('Pink',(255,127,230),.1,.24),('Cyan',(46,219,248),.15,.22),('Ice',(161,245,255),.1,.25),('Violet',(87,43,158),.25,.32),('Panel',(27,28,65),.1,.47),('Silver',(185,212,241),.8,.3),('DeepPink',(132,24,133),.2,.3),('White',(240,242,255),.1,.36),('Black',(12,15,34),.25,.45),('Turquoise',(23,124,167),.3,.29),('OrangeGold',(213,111,20),.65,.3)]
colorindex={x[0]:i for i,x in enumerate(P)}
def srgb(x):
 x=x/255;return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
images={}
for kind in ['Color','Metalness','Roughness']:
 im=bpy.data.images.new('GemChest_'+kind,width=256,height=256,alpha=True)
 pix=[]
 for y in range(256):
  for x in range(256):
   i=(y//64)*4+x//64;name,col,metal,rough=P[i]
   rgb=tuple(v/255 for v in col) if kind=='Color' else (metal,)*3 if kind=='Metalness' else (rough,)*3
   pix.extend((*rgb,1))
 if kind!='Color':im.colorspace_settings.name='Non-Color'
 im.pixels.foreach_set(pix);im.filepath_raw=str(O/'Textures'/('GemChest_'+kind+'.png'));im.file_format='PNG';im.save();im.pack();images[kind]=im
mat=bpy.data.materials.new('GemChest_GoldNavyCrystal');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF')
for kind,socket in [('Color','Base Color'),('Metalness','Metallic'),('Roughness','Roughness')]:
 n=mat.node_tree.nodes.new('ShaderNodeTexImage');n.image=images[kind];n.interpolation='Closest';mat.node_tree.links.new(n.outputs['Color'],bs.inputs[socket])

def uv_color(obj,color):
 if not obj.data.uv_layers:obj.data.uv_layers.new(name='PaletteUV')
 obj.data.uv_layers.active.name='PaletteUV'
 idx=colorindex[color];u=(idx%4+.5)/4;v=(idx//4+.5)/4
 for p in obj.data.polygons:
  for li in p.loop_indices:obj.data.uv_layers.active.data[li].uv=(u,v)
 obj.data.materials.clear();obj.data.materials.append(mat);return obj
def mesh(name,verts,faces,color):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);uv_color(o,color);return o
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def box(name,loc,size,color,bevel=0,rot=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.scale=size
 if rot:o.rotation_euler=rot
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  m=o.modifiers.new('Chunky bevel','BEVEL');m.width=bevel;m.segments=1
  bpy.ops.object.modifier_apply(modifier=m.name)
 return uv_color(o,color)
def cyl(name,loc,r,depth,color,vertices=8,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc,rotation=((math.pi/2,0,0) if axis=='Y' else (0,0,0)))
 o=bpy.context.object;o.name=name;return uv_color(o,color)
def gem(name,loc,scale,color,tilt=0):
 # Closed eight-sided crystal: broad shoulder, asymmetric long point.
 n=6;verts=[]
 for z,r,off in [(-.50,.40,0),(-.18,.70,math.pi/6),(.18,.53,math.pi/6)]:
  for i in range(n):
   a=2*math.pi*i/n+off;verts.append((math.cos(a)*r,math.sin(a)*r,z))
 verts.append((.04,-.03,.75));faces=[]
 faces.append(tuple(reversed(tuple(range(n)))))
 for k in range(2):
  for i in range(n):faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
 for i in range(n):faces.append((2*n+i,2*n+(i+1)%n,3*n))
 o=mesh(name,verts,faces,color);o.location=loc;o.scale=scale;o.rotation_euler[1]=tilt;return o
def diamond(name,loc,w,h,d,color):
 verts=[(-w/2,0,0),(0,0,-h/2),(w/2,0,0),(0,0,h/2),(0,-d/2,0),(0,d/2,0)]
 faces=[(i,(i+1)%4,4) for i in range(4)]+[((i+1)%4,i,5) for i in range(4)]
 o=mesh(name,verts,faces,color);o.location=loc;return o
def band(name,center,profile,color,n=32,start=0,end=2*math.pi,vertical=True):
 closed=abs((end-start)-2*math.pi)<1e-6;steps=n if closed else n+1;verts=[];faces=[]
 for i in range(steps):
  a=start+(end-start)*i/n
  for r,d in profile:
   verts.append((center[0]+r*math.sin(a),center[1]+d,center[2]+r*math.cos(a)) if vertical else (center[0]+r*math.sin(a),center[1]+r*math.cos(a),center[2]+d))
 k=len(profile)
 for i in range(n):
  j=(i+1)%steps
  for p in range(k):faces.append((i*k+p,j*k+p,j*k+(p+1)%k,i*k+(p+1)%k))
 if not closed:
  faces.append(tuple(reversed(tuple(range(k)))));faces.append(tuple((steps-1)*k+j for j in range(k)))
 return mesh(name,verts,faces,color)
def combine(parts,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
 return o
def hideall():
 for o in bpy.context.scene.objects:
  if o.type=='MESH':o.hide_render=True;o.hide_set(True)
def bounds(objects):
 bpy.context.view_layer.update()
 vs=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
 return [[min(v[i] for v in vs) for i in range(3)],[max(v[i] for v in vs) for i in range(3)]]
def tris(o):o.data.calc_loop_triangles();return len(o.data.loop_triangles)
models={};extra={}

# Appended to the shared low-poly helper definitions by build_chest.py.
W,D=8.4,5.4
BASE=.4; TOP=4.2; HINGE=Vector((0,-2.70,4.26))
body=[];lid=[];glow=[];lglow=[]

def prism_x(name,poly,x0,x1,color):
    n=len(poly);verts=[(x,y,z) for x in (x0,x1) for y,z in poly]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    return mesh(name,verts,faces,color)

def arch_points(r=2.7,h=1.65,z=4.26,n=10):
    return [(-r*math.cos(math.pi*i/n),z+h*math.sin(math.pi*i/n)) for i in range(n+1)]

def arch_band(name,x0,x1,color,r=2.74,h=1.71,width=.13):
    outer=arch_points(r,h,4.26,10)
    inner=list(reversed(arch_points(r-width,h-width,4.26,10)))
    return prism_x(name,outer+inner,x0,x1,color)

def torus_x(name,loc,r,tube,color,n=10,k=4):
    vs=[];fs=[]
    for i in range(n):
        a=2*math.pi*i/n
        for j in range(k):
            b=2*math.pi*j/k
            rr=r+tube*math.cos(b)
            vs.append((loc[0]+tube*math.sin(b),loc[1]+rr*math.sin(a),loc[2]+rr*math.cos(a)))
    for i in range(n):
        for j in range(k):fs.append((i*k+j,((i+1)%n)*k+j,((i+1)%n)*k+(j+1)%k,i*k+(j+1)%k))
    return mesh(name,vs,fs,color)

def jewel(name,loc,scale,color):
    o=gem(name,loc,scale,color)
    # Alternate broad crystal facets with the neighbouring palette shades.
    for poly in o.data.polygons:
        col=('Pink' if poly.index%4==0 else 'DeepPink' if poly.index%5==0 else color) if color=='Magenta' else ('Ice' if poly.index%4==0 else color)
        idx=colorindex[col];u=(idx%4+.5)/4;v=(idx//4+.5)/4
        for li in poly.loop_indices:o.data.uv_layers.active.data[li].uv=(u,v)
    return o

# Low navy plinth, light gold shoulder and a recessed magenta front channel.
body.append(box('Navy plinth',(0,0,.21),(9.0,6.0,.42),'Navy',.13))
body.append(box('Gold base shoulder',(0,0,.48),(8.92,5.92,.20),'Gold',.07))
body.append(box('Navy well floor',(0,0,.72),(8.18,5.18,.35),'NavyLight',.10))
for sx in (-1,1):
    for sy in (-1,1):
        body.append(box('Gold corner boot',(sx*4.05,sy*2.55,.66),(.84,.82,.54),'Gold',.12))
glow.append(box('Front pink base light',(0,3.015,.28),(4.4,.055,.10),'Magenta',.018))
for sx in (-1,1):
    body.append(box('Cyan base side light',(sx*3.2,3.015,.28),(.74,.055,.10),'Cyan',.018))

# Real hollow body: separate closed panels around an open well, no solid filler.
body.append(box('Front wall',(0,2.49,2.47),(8.30,.42,3.46),'Navy',.09))
body.append(box('Back wall',(0,-2.49,2.47),(8.30,.42,3.46),'Navy',.09))
for sx in (-1,1):
    body.append(box('Side wall',(sx*3.99,0,2.47),(.42,4.74,3.46),'NavyLight',.08))
body.append(box('Front violet inset',(0,2.718,2.48),(6.12,.10,2.40),'Violet',.12))
body.append(box('Inner well floor',(0,0,.95),(7.55,4.55,.16),'DeepPink',.05))

# Chunky belt bands, rim and side handles.
for sx in (-1,1):
    for sy in (-1,1):
        body.append(box('Gold vertical strap',(sx*2.88,sy*2.74,2.51),(.51,.18,3.26),'Gold',.05))
        body.append(box('Strap silver pin',(sx*2.88,sy*2.85,1.13),(.20,.06,.20),'GoldLight',.025))
    body.append(box('Side gold bottom band',(sx*4.22,0,1.03),(.16,5.36,.25),'Gold',.045))
    body.append(box('Side handle socket',(sx*4.25,0,2.64),(.16,1.32,1.12),'Gold',.06))
    body.append(torus_x('Octagonal gold carry handle',(sx*4.49,0,2.40),.54,.15,'Gold',10,4))
    body.append(box('Side cyan inset',(sx*4.315,0,3.43),(.07,1.45,.15),'Cyan',.025))
for sy in (-1,1):
    body.append(box('Gold well lip long',(0,sy*2.51,4.145),(8.43,.43,.11),'GoldLight',.025))
for sx in (-1,1):
    body.append(box('Gold well lip side',(sx*3.99,0,4.145),(.43,4.74,.11),'GoldLight',.025))

# Front oversized gem clasp. It stays on the body so no separate lock rig is needed.
body.append(diamond('Gold gem bezel',(0,2.87,3.60),1.82,1.96,.30,'Gold'))
body.append(diamond('Deep violet gem inset',(0,3.04,3.60),1.46,1.60,.16,'DeepPink'))
glow.append(diamond('Magenta gem clasp',(0,3.16,3.60),1.14,1.30,.30,'Magenta'))
for sx in (-1,1):
    body.append(diamond('Small cyan face jewel',(sx*1.78,2.81,2.55),.42,.58,.18,'Cyan'))

# Lid shell is a sealed arched prism. Gold straps follow its curvature.
lid.append(prism_x('Rounded navy lid',arch_points(),-4.20,4.20,'Navy'))
for sx in (-1,1):
    lid.append(prism_x('Violet lid endcap',arch_points(2.57,1.50,4.31,10),sx*4.20,sx*4.27,'Violet'))
    lid.append(arch_band('Gold end rim',min(sx*4.27,sx*4.36),max(sx*4.27,sx*4.36),'Gold',2.76,1.72,.15))
    lid.append(arch_band('Gold curved lid belt',sx*2.88-.30,sx*2.88+.30,'Gold',2.77,1.73,.15))
    lid.append(box('Gold belt foot',(sx*2.88,2.72,4.36),(.60,.16,.20),'GoldLight',.03))
    # Low cyan crystal on each outer shoulder; these move with the lid.
    lid.append(jewel('Cyan lid shoulder gem',(sx*3.76,0,5.86),(.42,.43,.76),'Cyan'))
lid.append(box('Lid underside inset',(0,0,4.255),(6.95,4.12,.055),'Violet',0))
lid.append(box('Lid front gold seam',(0,2.73,4.33),(8.20,.14,.18),'Gold',.04))
for sx in (-1,1):
    lid.append(cyl('Gold rear hinge barrel',(sx*2.65,-2.74,4.28),.27,.82,'Gold',10,'Y'))
    # Barrel is decorative; the common mathematical pivot drives the whole lid.

# Crystal crown rooted on top, sufficiently chunky to read across the mine.
lid.append(box('Crown navy seat',(0,0,5.95),(2.66,1.18,.28),'NavyLight',.10))
lid.append(box('Crown gold collar',(0,0,6.10),(2.50,1.04,.18),'Gold',.07))
lglow.append(jewel('Main magenta lid crystal',(0,0,6.61),(.72,.66,1.15),'Magenta'))
for sx in (-1,1):
    o=jewel('Magenta crown side crystal',(sx*.87,0,6.38),(.48,.48,.75),'Magenta');o.rotation_euler[1]=sx*.22;lglow.append(o)

# Treasure visible only when the lid opens: low, large facets, no floating particles.
for i,(x,y,s) in enumerate([(-2.8,.6,.65),(-1.75,-.6,.8),(-.8,.65,.82),(.35,-.4,.92),(1.35,.8,.7),(2.4,-.65,.85),(2.85,.8,.56)]):
    o=jewel('Interior treasure gem',(x,y,1.22),(s,s,s*.9),'Magenta' if i%3 else 'Cyan');o.rotation_euler=(.20*(i%2),.17*(i-3),i*.75);body.append(o)

objects=[combine(body,'ChestBody'),combine(lid,'ChestLid'),combine(glow,'ChestGlow'),combine(lglow,'LidGlow')]
for o in objects:
    if o.name in ('ChestLid','LidGlow'):
        active(o);bpy.context.scene.cursor.location=HINGE;bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o['partRole']='Moving lid group' if o.name in ('ChestLid','LidGlow') else 'Stationary body group'
    o['nominalStudUnits']=True

# A low emission shader makes actual preview renders readable; Studio controls
# its own optional Neon/light/particle treatment on the two dedicated glow meshes.
em=mat.copy();em.name='GemChest_Glow'
eb=em.node_tree.nodes.get('Principled BSDF')
colnode=next(n for n in em.node_tree.nodes if n.type=='TEX_IMAGE' and n.image==images['Color'])
em.node_tree.links.new(colnode.outputs['Color'],eb.inputs['Emission Color']);eb.inputs['Emission Strength'].default_value=.35
for o in objects:
    if o.name in ('ChestGlow','LidGlow'):o.data.materials[0]=em

root=bpy.data.objects.new('GemChest',None);bpy.context.scene.collection.objects.link(root)
for o in objects:o.parent=root
bpy.context.scene.cursor.location=(0,0,0)
bpy.context.scene.unit_settings.system='NONE'
manifest={'date':'2026-11-11','model':'GemChest','sourceAxes':'Blender X right, Y FRONT, Z up. Front is +Y intentionally.','nominalBlenderToRoblox':'(x,y,z) -> (x,z,-y); final importer orientation/scale must be checked in Studio.','pivotMeaning':'Root at ground centre of the closed chest.','hingeBlender':list(HINGE),'hingeRobloxNominal':[0,4.26,2.70],'frontRobloxNominal':[0,0,-1],'openingPositiveXDegrees':100,'containsText':False,'containsRuntimeEffects':False,'textureSize':256,'parts':[]}
for o in objects:manifest['parts'].append({'name':o.name,'triangles':tris(o),'boundsBlender':bounds([o]),'originBlender':list(o.location),'movesWithLid':o.name in ('ChestLid','LidGlow')})
manifest['triangles']=sum(tris(o) for o in objects);manifest['boundsBlender']=bounds(objects)
manifest['textureMaps']={k+'Map':'Textures/GemChest_'+k+'.png' for k in ['Color','Metalness','Roughness']}
(O/'Model-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
assert manifest['triangles']<=3000,manifest['triangles']

bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.fbx(filepath=str(O/'FBX'/'GemChest.fbx'),use_selection=True,object_types={'MESH','EMPTY'},axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,bake_anim=False,add_leaf_bones=False)
(O/'GLB').mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(O/'GLB'/'GemChest.glb'),export_format='GLB',use_selection=True,export_yup=True)
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Blender'/'GemChest.blend'),compress=True)

# Actual closed/open model renders, not AI concept images.
world=bpy.data.worlds.new('ChestStudio');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.40,.46,.60,1);world.node_tree.nodes['Background'].inputs[1].default_value=.65;bpy.context.scene.world=world
for name,loc,power,size in [('Key',(-7,10,13),1700,8),('Fill',(9,6,9),1000,8),('Rim',(1,-8,12),1800,6)]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,3.5))-o.location).to_track_quat('-Z','Y').to_euler()
camd=bpy.data.cameras.new('PreviewCamera');cam=bpy.data.objects.new('PreviewCamera',camd);bpy.context.scene.collection.objects.link(cam);bpy.context.scene.camera=cam;camd.type='ORTHO';camd.ortho_scale=12.5
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=80;scene.cycles.use_denoising=False;scene.render.resolution_x=1100;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True;scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast';scene.view_settings.exposure=-.35
def render(name,location,target=(0,0,3.3),scale=12.5):
    cam.location=location;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();camd.ortho_scale=scale;scene.render.filepath=str(O/'Previews'/(name+'.png'));bpy.ops.render.render(write_still=True)
render('GemChest-Closed',(10,16,11))
render('GemChest-Front',(0,18,6.5))
for o in objects:
    if o.name in ('ChestLid','LidGlow'):o.rotation_euler[0]=math.radians(100)
render('GemChest-Open',(10,16,22),(0,-.6,4.4),16.0)
for o in objects:
    if o.name in ('ChestLid','LidGlow'):o.rotation_euler[0]=0
print('GEM_CHEST_COMPLETE '+str(manifest['triangles'])+' triangles',flush=True)
