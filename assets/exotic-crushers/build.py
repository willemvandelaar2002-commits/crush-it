import bpy,bmesh,math,json,os
from pathlib import Path
from mathutils import Vector,Matrix
from math import sin,cos,pi,radians as rad
P=Path(__file__).resolve().parent;O=P/'out';O.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
S=bpy.context.scene;S.frame_end=72;S.render.fps=30;S.view_settings.view_transform='Khronos PBR Neutral'
pal={'Ink':'161A2C','Graphite':'353946','Slate':'596071','Silver':'B5C4CF','Cream':'FFF1D7','Orange':'FF7037','Coral':'FF9B69','DarkOrange':'BC412A','Mint':'6DE8B0','Teal':'158A85','Glow':'ADFFE0','Black':'111826','Yellow':'FFCF53'}
def rgb(h):return tuple(int(h[i:i+2],16)/255 for i in [0,2,4])
def linear(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
M={}
for n,h in pal.items():
 m=bpy.data.materials.new(n);m.use_nodes=True;c=tuple(linear(v) for v in rgb(h))+(1,);m.diffuse_color=c
 p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=c;p.inputs['Roughness'].default_value=.32;p.inputs['Metallic'].default_value=.42 if n in ['Silver','Graphite'] else .10
 if n=='Glow':p.inputs['Emission Color'].default_value=c;p.inputs['Emission Strength'].default_value=.3
 M[n]=m
C=None
def collection(n):
 c=bpy.data.collections.new(n);S.collection.children.link(c);return c
def link(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 C.objects.link(o)
def empty(n,p=None,at=(0,0,0),rot=(0,0,0)):
 o=bpy.data.objects.new(n,None);C.objects.link(o);o.parent=p;o.location=at;o.rotation_euler=rot;o.empty_display_size=.10;return o
def finish(o,p,n,at,mat,r,b):
 link(o);o.name=n;o.parent=p;o.location=at;o.rotation_euler=r;o.data.materials.append(M[mat])
 if b:
  v=o.modifiers.new('Chamfer','BEVEL');v.width=b;v.segments=1
  w=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');w.keep_sharp=True
 return o
def box(p,n,at,d,mat,r=(0,0,0),b=.045):
 bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object
 for v in o.data.vertices:
  for i in range(3):v.co[i]*=d[i]
 return finish(o,p,n,at,mat,r,b)
def cyl(p,n,at,R,dep,mat,axis=(0,0,1),N=20,b=.023):
 bpy.ops.mesh.primitive_cylinder_add(vertices=N,radius=R,depth=dep);o=bpy.context.object
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 return finish(o,p,n,at,mat,Vector(axis).to_track_quat('Z','Y').to_euler(),b)
def mesh(p,n,at,vs,fs,mat,b=.02):
 me=bpy.data.meshes.new(n);me.from_pydata(vs,[],fs);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 return finish(bpy.data.objects.new(n,me),p,n,at,mat,(0,0,0),b)
def prof(p,n,at,pts,dep,mat,b=.04):
 k=len(pts)
 return mesh(p,n,at,[(x,y,z) for y in [-dep/2,dep/2] for x,z in pts],[tuple(range(k)),tuple(range(k,2*k))]+[(i,(i+1)%k,(i+1)%k+k,i+k) for i in range(k)],mat,b)
def arc(p,n,at,R,w,dep,a,b,mat,be=.02):
 t=[rad(a+(b-a)*i/max(4,math.ceil((b-a)/8))) for i in range(max(4,math.ceil((b-a)/8))+1)]
 return prof(p,n,at,[(R*cos(v),R*sin(v)) for v in t]+[((R-w)*cos(v),(R-w)*sin(v)) for v in reversed(t)],dep,mat,be)
def ring(p,n,at,R,w,dep,mat):
 for i in range(4):arc(p,n,at,R,w,dep,i*90,(i+1)*90,mat)
def bar(p,n,a,b,w,d,mat):
 a,b=Vector(a),Vector(b);v=b-a
 return box(p,n,(a+b)/2,(w,d,v.length),mat,v.to_track_quat('Z','Y').to_euler())
def shaft(p,n,a,b,R,mat):
 a,b=Vector(a),Vector(b);v=b-a
 return cyl(p,n,(a+b)/2,R,v.length,mat,v,N=16)
def hinge(p,x,y,z,R,mat='Orange'):
 cyl(p,'Bearing',(x,y,z),R,.20,'Graphite',(0,1,0))
 cyl(p,'Bearing rim',(x,y-.11,z),R*.75,.08,mat,(0,1,0))
 cyl(p,'Axle cap',(x,y-.16,z),R*.34,.10,'Silver',(0,1,0),N=12)
def warning(p,at,w=1.2):
 box(p,'Warning inset',at,(w,.045,.17),'Black',b=.018)
 for i in range(4):box(p,'Warning stripe',(at[0]+(i-1.5)*w/5,at[1]-.03,at[2]),(w/8,.024,.145),'Yellow',(0,rad(-24),0),.006)
def bed(p,at,d=(1.35,1.04,.22),mat='Graphite'):
 box(p,'Anvil',at,d,mat,b=.075);box(p,'Strike surface',(at[0],at[1],at[2]+d[2]/2+.025),(d[0]*.85,d[1]*.85,.05),'Silver',b=.025)
def wheel(p,n,at,R,mat):
 ring(p,n,at,R,.12,.15,mat)
 cyl(p,'Wheel hub',at,.15,.25,'Graphite',(0,1,0))
 for i in range(6):
  a=i*pi/3
  bar(p,'Wheel spoke',(at[0],at[1],at[2]),(at[0]+(R-.07)*cos(a),at[1],at[2]+(R-.07)*sin(a)),.075,.095,mat)
D={}
def start(id,title):
 global C
 C=collection(id);r=empty(id);f=empty(id+'_Frame',r)
 box(f,'Base',(0,0,.13),(4.56,2.92,.26),'Ink',b=.09)
 box(f,'Deck',(0,0,.32),(4.44,2.81,.17),'Graphite',b=.068)
 box(f,'Deck insert',(0,.03,.435),(4.02,2.49,.065),'Slate',b=.03)
 for x in [-1,1]:
  for y in [-1,1]:
   box(f,'Coral corner',(x*2.03,y*1.23,.29),(.43,.43,.31),'Orange',b=.08)
   cyl(f,'Deck rivet',(x*1.99,y*1.20,.49),.075,.05,'Silver',N=8,b=.01)
  box(f,'Signal',(x*1.67,-1.438,.30),(.44,.04,.075),'Mint',b=.012)
 warning(f,(0,-1.445,.295))
 d={'id':id,'title':title,'root':r,'frame':f,'col':C,'groups':[],'input':(0,-.3,1.0),'bed':.75};D[id]=d
 return d,f
def move(d,n,at,delta=(0,0,0),turn=(0,0,0),rot=(0,0,0),keys=None,ratio=None):
 o=empty(d['id']+'_'+n,d['root'],at,rot)
 d['groups'].append(dict(o=o,name=n,delta=delta,turn=turn,ratio=ratio,keys=keys or [(1,0),(16,0),(34,1),(40,1),(57,0),(72,0)]))
 return o
# MAGLEV MAULER: long horizontal guide sled with a fixed far-end wall.
d,f=start('MaglevMauler','Maglev Mauler');d['input']=(.81,-.28,.99);d['bed']=.81
box(f,'Rail deck',(0,-.10,.55),(3.89,1.59,.19),'Black',b=.08)
for y in [-.76,.45]:
 box(f,'Magnetic rail',(0,y,.70),(3.64,.14,.19),'Mint',b=.033)
 box(f,'Rail trace',(0,y-.075,.71),(3.32,.035,.058),'Glow',b=.01)
 for x in [-1.70,1.70]:box(f,'Rail lock',(x,y,.64),(.26,.30,.29),'Orange',b=.044)
box(f,'Shock wall',(1.39,-.16,1.22),(.34,1.74,1.18),'Orange',b=.11)
box(f,'Shock wall bumper',(1.18,-.16,1.20),(.12,1.43,.86),'Graphite',b=.055)
for y in [-.65,.33]:box(f,'Wall rib',(1.58,y,1.22),(.20,.16,1.11),'Coral',b=.028)
bed(f,(.81,-.28,.71),(.58,.73,.15))
o=move(d,'Sled',(-.78,-.18,1.03),(.91,0,0))
prof(o,'Impact wedge',(0,0,0),[(-.78,-.21),(.76,-.21),(.79,.12),(.48,.49),(-.63,.49),(-.81,.25)],1.25,'Graphite',.08)
box(o,'Mint underside',(0,0,-.24),(1.30,1.15,.10),'Mint',b=.023)
box(o,'Steel impact die',(.79,0,.08),(.13,1.15,.53),'Silver',b=.047)
bar(o,'Handle left',(-.43,.24,.41),(-.31,.24,.75),.12,.13,'Graphite')
bar(o,'Handle top',(-.31,.24,.75),(.29,.24,.75),.13,.13,'Graphite')
bar(o,'Handle right',(.29,.24,.75),(.40,.24,.41),.12,.13,'Graphite')
box(o,'Handle enamel',(0,.16,.75),(.29,.19,.09),'Mint',b=.023)
for i in range(3):box(o,'Side speed trace',((i-1)*.16,-.637,.15),(.075,.032,.24),'Glow',(0,rad(25),0),.014)
# ORIGAMI CLAMP: three folding broad fan plates with rear hinges.
d,f=start('OrigamiClamp','Origami Clamp');d['input']=(0,-.61,.99)
bed(f,(0,-.54,.65),(1.91,1.30,.19));d['bed']=.77
for x in [-1,1]:
 prof(f,'Fan pedestal',(x*1.33,.77,.46),[(-.25,0),(.25,0),(.22,.58),(.12,.82),(-.14,.82)],.68,'Graphite',.062)
 hinge(f,x*1.33,.39,1.07,.26)
 shaft(f,'Assist rail',(x*1.25,-.90,.65),(x*1.25,.52,1.03),.07,'Silver')
for i in range(3):
 at=(0,.64, .87+i*.12);a=rad(29+i*16)
 o=move(d,'Fold_'+str(i+1),at,turn=(a,0,0),rot=(-a,0,0))
 box(o,'Broad fold plate',(0,-.83,0),(2.35,1.72,.11),'Orange' if i!=1 else 'Coral',b=.035)
 for x in [-1,1]:box(o,'Fold edge',(x*1.14,-.83,.075),(.07,1.66,.11),'DarkOrange',b=.018)
 box(o,'Fold spine',(0,-1.64,.05),(2.30,.10,.16),'Orange',b=.025)
 cyl(o,'Hinge rod',(0,0,0),.083,2.65,'Silver',(1,0,0))
 if i==0:warning(o,(0,-1.712,.011),1.57)
# WRECKING WINCH: offset crane, rotating drum, extending cable and falling block.
d,f=start('WreckingWinch','Wrecking Winch');d['input']=(-.62,-.43,1.01);d['bed']=.82
bed(f,(-.62,-.43,.71),(1.43,1.07,.18),'Teal')
prof(f,'Crane column',(1.25,.28,.46),[(-.48,0),(.49,0),(.34,1.01),(.12,1.94),(-.17,2.17),(-.38,1.35)],.86,'Cream',.075)
box(f,'Crane foot',(1.25,.28,.60),(1.10,1.05,.24),'Orange',b=.066)
bar(f,'Cantilever',(1.23,.24,2.60),(-.75,.24,3.14),.38,.60,'Cream')
box(f,'Boom nose',(-.73,.24,3.11),(.52,.70,.37),'Orange',b=.065)
bar(f,'Brace',(1.37,.67,.68),(.94,.67,2.51),.17,.17,'Graphite')
hinge(f,1.12,-.21,2.66,.28,'Orange')
o=move(d,'WinchDrum',(.49,.28,3.04),turn=(2*pi,0,0),keys=[(1,0),(34,1),(57,0),(72,0)])
cyl(o,'Cable spool',(0,0,0),.31,.70,'Teal',(1,0,0))
for x in [-.38,.38]:cyl(o,'Drum rim',(x,0,0),.40,.09,'Orange',(1,0,0))
for x in [-.26,-.13,0,.13,.26]:cyl(o,'Wound cable',(x,0,0),.327,.055,'Black',(1,0,0))
o=move(d,'DropWeight',(-.64,-.35,1.98),(0,0,-.76))
box(o,'Wrecking block',(0,0,0),(1.02,.85,.66),'Graphite',b=.11)
box(o,'Coral weight face',(0,-.442,0),(.72,.06,.40),'Orange',b=.046)
warning(o,(0,-.481,0),.52)
box(o,'Cable shackle',(0,0,.38),(.26,.23,.18),'Orange',b=.032)
o=move(d,'Cable',(-.64,-.35,3.08),ratio=1+.76/.70)
cyl(o,'Thick lifting cable',(0,0,-.35),.038,.70,'Black',N=12,b=.006)
# CAM CRUNCHER: two eccentrics spinning above a vertical follower stamp.
d,f=start('CamCruncher','Cam Cruncher');d['input']=(0,-.38,1.0)
bed(f,(0,-.38,.67));d['bed']=.805
for side in [-1,1]:
 prof(f,'Cam support',(side*1.42,.12,.46),[(-.30,0),(.30,0),(.26,1.81),(.13,1.97),(-.17,1.97),(-.31,.47)],.70,'Teal',.065)
 box(f,'Cam leg skin',(side*1.42,-.25,1.30),(.40,.10,1.22),'Mint',b=.039)
 box(f,'Guide housing',(side*.76,.02,1.43),(.22,.60,1.28),'Graphite',b=.043)
 shaft(f,'Slide guide',(side*.59,-.24,.95),(side*.59,-.24,1.99),.057,'Silver')
o=move(d,'Camshaft',(0,-.02,2.27),turn=(2*pi,0,0),keys=[(1,0),(34,.5),(57,1),(72,1)])
cyl(o,'Shaft',(0,0,0),.11,3.45,'Graphite',(1,0,0))
for x in [-.58,.58]:
 g=empty('Cam lobe',o,(x,0,.18))
 # Elliptical lobe offset from shaft, not a roller feeder.
 cyl(g,'Mint eccentric',(0,0,0),.43,.22,'Mint',(1,0,0),N=24)
g=empty('Flywheel orientation',o,(1.78,0,0),(0,0,pi/2))
wheel(g,'Cam flywheel',(0,0,0),.58,'Silver')
o=move(d,'Stamp',(0,-.35,1.58),(0,0,-.49))
box(o,'Follower stamp',(0,0,0),(1.35,.95,.27),'Orange',b=.073)
box(o,'Stamp face',(0,0,-.16),(1.18,.80,.10),'Cream',b=.032)
box(o,'Follower stem',(0,.24,.39),(.30,.29,.72),'Orange',b=.04)
for x in [-.55,.55]:cyl(o,'Cam follower roller',(x,.20,.75),.13,.22,'Silver',(1,0,0))
# SCREW STAMPER: rotating threaded screw and handle drive a heavy die.
d,f=start('ScrewStamper','Screw Stamper');d['input']=(.16,-.28,1.01);d['bed']=.82
bed(f,(.16,-.28,.70),(1.62,1.17,.19),'Teal')
prof(f,'Single cast C frame',(-1.02,.35,.47),[(-.43,0),(.32,0),(.32,2.16),(1.96,2.16),(1.96,2.54),(.01,2.54),(-.43,2.15)],.95,'Orange',.095)
prof(f,'Cream structural skin',(-1.03,-.15,.57),[(-.25,0),(.18,0),(.18,2.09),(1.81,2.09),(1.81,2.32),(-.02,2.32),(-.25,2.06)],.12,'Cream',.05)
for z in [.81,1.43,2.25]:cyl(f,'Frame bolt',(-1.14,-.25,z),.08,.05,'Silver',(0,1,0),N=6)
cyl(f,'Thread nut',(.24,.10,2.74),.33,.35,'Graphite',N=12)
o=move(d,'Screw',(.24,.10,1.99),(0,0,-.52),(0,0,2*pi))
cyl(o,'Screw core',(0,0,.36),.15,1.58,'Graphite')
# Rectangular thread flight, one helical strip with solid thickness.
steps=180;vs=[]
for i in range(steps+1):
 a=i*2*pi*7/steps;z=-.35+i*1.47/steps
 for r,h in [(.15,-.025),(.26,-.025),(.26,.025),(.15,.025)]:vs.append((r*cos(a),r*sin(a),z+h))
fs=[]
for i in range(steps):
 for j in range(4):fs.append((i*4+j,i*4+(j+1)%4,(i+1)*4+(j+1)%4,(i+1)*4+j))
fs+=[(0,1,2,3),(steps*4+3,steps*4+2,steps*4+1,steps*4)]
mesh(o,'Helical thread',(0,0,0),vs,fs,'Silver',0)
o=move(d,'Handle',(.24,.10,3.27),turn=(0,0,2*pi))
cyl(o,'Handle hub',(0,0,0),.27,.19,'Graphite',N=12)
for i in range(6):
 a=i*pi/3
 shaft(o,'Six spoke grip',(0,0,0),(.66*cos(a),.66*sin(a),0),.057,'Cream')
 cyl(o,'Grip end',(.66*cos(a),.66*sin(a),0),.078,.13,'Silver')
o=move(d,'Shoe',(.24,-.16,1.56),(0,0,-.52))
box(o,'Press shoe',(0,0,0),(1.46,1.02,.28),'Graphite',b=.071)
box(o,'Die',(0,0,-.17),(1.27,.84,.085),'Silver',b=.028)
# DRAWBRIDGE CRUSHER: a gear-driven deck hinged at the rear.
d,f=start('DrawbridgeCrusher','Drawbridge Crusher');d['input']=(0,-.40,1.01);d['bed']=.81
bed(f,(0,-.30,.68),(2.55,1.54,.20))
for side in [-1,1]:
 prof(f,'Hinge stand',(side*1.45,.71,.46),[(-.27,0),(.27,0),(.25,.60),(.10,.76),(-.14,.73),(-.26,.34)],.62,'Orange',.065)
 hinge(f,side*1.45,.38,1.01,.22)
o=move(d,'Bridge',(0,.73,1.02),turn=(rad(58),0,0),rot=(-rad(58),0,0))
box(o,'Crushing deck',(0,-.93,0),(2.55,1.95,.16),'Cream',b=.046)
for x in [-.88,-.45,0,.45,.88]:box(o,'Reinforcing rib',(x,-.93,.12),(.075,1.80,.17),'Silver',b=.021)
box(o,'Coral front crossbeam',(0,-1.87,.06),(2.75,.25,.37),'Orange',b=.065)
for x in [-.84,-.28,.28,.84]:box(o,'Mint leading mark',(x,-2.004,.07),(.32,.028,.13),'Mint',(0,rad(-19),0),.009)
cyl(o,'Hinge shaft',(0,0,0),.095,3.1,'Graphite',(1,0,0))
for side in [-1,1]:
 g=empty('Sector orient',o,(side*1.45,-.01,0),(0,0,pi/2))
 arc(g,'Gear sector',(0,0,0),.94,.13,.15,0,105,'Graphite')
 for a in [0,rad(54),rad(105)]:
  bar(g,'Sector spoke',(0,0,0),(.89*cos(a),0,.89*sin(a)),.10,.13,'Graphite')
 for i in range(12):
  a=rad(i*9)
  box(g,'Gear tooth',(.96*cos(a),0,.96*sin(a)),(.13,.18,.12),'Cream',(0,pi/2-a,0),.015)


# Export a palette-textured mesh per rigid assembly and the existing motion kit's metadata.
palnames=list(pal)
atlas=bpy.data.images.new('Exotic palette',width=64,height=64,alpha=False)
atlas.pixels.foreach_set([v for y in range(64) for x in range(64) for v in (*rgb(pal[palnames[((y//16)*4+x//16)%len(palnames)]]),1)])
atlas.update();atlas.filepath_raw=str(P/'palette.png');atlas.file_format='PNG';atlas.save();atlas.pack()
a=bpy.data.materials.new('Exotic colours');a.use_nodes=True
tex=a.node_tree.nodes.new('ShaderNodeTexImage');tex.image=atlas;tex.interpolation='Closest'
a.node_tree.links.new(tex.outputs['Color'],a.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
a.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.36
E=collection('Export');records=[];lua=['--!strict','-- Authored Exotic rigs. Basis matches the existing Studio FBX imports: (-x,z,y).','return {']
Q=Matrix(((-1,0,0),(0,0,1),(0,1,0)))
def v3(v):return 'Vector3.new('+','.join(f'{x:.6g}' for x in v)+')'
def merge(src,name,root):
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
 T0=src.matrix_world.inverted();vs=[];fs=[];colors=[];smooth=[]
 for ob in src.children_recursive:
  if ob.type!='MESH':continue
  ev=ob.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();T=T0@ob.matrix_world;n=len(vs)
  vs.extend(tuple(T@v.co) for v in me.vertices)
  for tr in me.loop_triangles:
   fs.append(tuple(n+i for i in tr.vertices));f=me.polygons[tr.polygon_index]
   colors.append(palnames.index(me.materials[f.material_index].name));smooth.append(f.use_smooth)
  ev.to_mesh_clear()
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();me.materials.append(a);uv=me.uv_layers.new()
 for f,col,sm in zip(me.polygons,colors,smooth):
  f.use_smooth=sm;u,v=(col%4+.5)/4,(col//4+.5)/4
  for j,(dx,dy) in zip(f.loop_indices,[(-.02,-.02),(.02,-.02),(0,.02)]):uv.data[j].uv=(u+dx,v+dy)
 o=bpy.data.objects.new(name,me);E.objects.link(o);o.parent=root;o.matrix_basis=src.matrix_world
 return o,len(fs)
for d in D.values():
 root=bpy.data.objects.new('ImportRoot',None);E.objects.link(root);obs=[root];rr=[];allpts=[]
 specs=[dict(o=d['frame'],name='Frame',delta=(0,0,0),turn=(0,0,0),ratio=None,keys=[])]+d['groups']
 for m in specs:
  src=m['o'];o,n=merge(src,m['name'],root);obs.append(o);bpy.context.view_layer.update()
  pts=[o.matrix_world@v.co for v in o.data.vertices];allpts+=pts
  bounds=[[fn(p[i] for p in pts) for i in range(3)] for fn in [min,max]]
  converted=[Q@p for p in pts]
  lo=Vector([min(p[i] for p in converted) for i in range(3)]);hi=Vector([max(p[i] for p in converted) for i in range(3)])
  rr.append(dict(name=m['name'],triangles=n,bounds=bounds,pivot=list(src.location),rotation=list(src.rotation_euler),delta=list(m['delta']),turn=list(m['turn']),ratio=m['ratio'],keys=m['keys'],
   center=list((lo+hi)/2),size=list(hi-lo),origin=list(Q@src.location)))
 bounds=[[fn(p[i] for p in allpts) for i in range(3)] for fn in [min,max]]
 assert abs(bounds[0][2])<.001 and bounds[1][2]<4.05,(d['id'],bounds)
 assert max(p['triangles'] for p in rr)<10000,(d['id'],rr)
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=root
 assert 'FINISHED' in bpy.ops.export_scene.fbx(filepath=str(O/(d['id']+'.fbx')),use_selection=True,bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y',object_types={'EMPTY','MESH'})
 records.append(dict(id=d['id'],title=d['title'],input=d['input'],bedTop=d['bed'],bounds=bounds,parts=rr))
 size=Vector([bounds[1][0]-bounds[0][0],bounds[1][2]-bounds[0][2],bounds[1][1]-bounds[0][1]])
 lua+=[' '+d['id']+'={kit="motion",grow=true,size='+v3(size)+',bedTop='+str(d['bed'])+',','  inputCenter='+v3(Q@Vector(d['input']))+',inputSize=.38,','  parts={']
 for r in rr:lua+=['   '+r['name']+'={center='+v3(r['center'])+',size='+v3(r['size'])+',origin='+v3(r['origin'])+'},']
 lua+=['  },motion={']
 for m in d['groups']:
  keystr='{'+','.join('{'+f'{(t-1)/71:.7g},{val:.7g}'+'}' for t,val in m['keys'])+'}'
  base='{name="'+m['name']+'",keys='+keystr+','
  if any(m['delta']):lua+=['   '+base+'kind="move",vector='+v3(Q@Vector(m['delta']))+'},']
  if any(m['turn']):
   # These authored mechanisms rotate about one local axis at a time.
   i=next(i for i,x in enumerate(m['turn']) if x)
   axis=Vector([int(j==i) for j in range(3)])
   # For our rigs, an X hinge has its rest rotation on X, and other pivots are identity.
   lua+=['   '+base+'kind="rotate",axis='+v3(Q@axis)+',angle='+str(m['turn'][i])+'},']
  if m['ratio']:
   lua+=['   '+base+'kind="extend",axis="Y",ratio='+str(m['ratio'])+'},']
 lua+=['  },contact={'+','.join('"'+m['name']+'"' for m in d['groups'] if m['name'] not in ['WinchDrum','Cable','Handle','Camshaft'])+'}},']
 for o in reversed(obs):bpy.data.objects.remove(o,do_unlink=True)
 print('FBX',d['id'],sum(r['triangles'] for r in rr),flush=True)
lua+=['}']
(O/'ExoticCrusherAssets.luau').write_text('\n'.join(lua)+'\n')
(O/'Model-manifest.json').write_text(json.dumps(records,indent=2)+'\n')
bpy.data.collections.remove(E)
for d in D.values():
 for m in d['groups']:
  o=m['o'];p0=Vector(o.location);r0=Vector(o.rotation_euler)
  for t,val in m['keys']:
   o.location=p0+Vector(m['delta'])*val;o.rotation_euler=r0+Vector(m['turn'])*val
   o.scale=(1,1,1+(m['ratio']-1)*val) if m['ratio'] else (1,1,1)
   for path in ['location','rotation_euler','scale']:o.keyframe_insert(data_path=path,frame=t,group=m['name'])
  o.animation_data.action.name=d['id']+' '+m['name']
 d['root']['crusher_id']=d['id']
S.frame_set(1);S.timeline_markers.new('Contact',frame=34)
# Shared render studio.
C=collection('Studio setup');studio=C
def point(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
def light(n,at,energy,c,size):
 data=bpy.data.lights.new(n,'AREA');data.energy=energy;data.color=c;data.size=size
 o=bpy.data.objects.new(n,data);C.objects.link(o);o.location=at;point(o,(0,0,1.5))
light('Softbox',(-3,-5,6),650,(.97,.98,1),5)
light('Fill',(4,-2,4),370,(1,.87,.7),4)
light('Rim',(1,3,5),700,(.55,.75,1),3)
S.world=bpy.data.worlds.new('Studio world');S.world.use_nodes=True
S.world.node_tree.nodes['Background'].inputs[0].default_value=(.15,.22,.35,1)
S.world.node_tree.nodes['Background'].inputs[1].default_value=.45
cd=bpy.data.cameras.new('Camera');cd.type='ORTHO';cd.ortho_scale=6.2
cam=bpy.data.objects.new('Camera',cd);C.objects.link(cam);cam.location=(4,-11,5.4);point(cam,(0,0,1.65));S.camera=cam
floor=box(None,'Studio floor',(0,0,-.12),(60,60,.24),'Ink',b=0)
S.render.engine='CYCLES';S.cycles.samples=16;S.cycles.use_denoising=True;S.cycles.max_bounces=5
S.render.image_settings.file_format='PNG';S.render.resolution_percentage=100
for i,d in enumerate(D.values()):d['root'].location=((i%3-1)*5.6,(1-i//3)*4.6,0)
bpy.ops.object.select_all(action='DESELECT')
studio.hide_viewport=True;studio.hide_render=True;S.camera=None
for screen in bpy.data.screens:
 for ar in screen.areas:
  if ar.type=='VIEW_3D':
   sp=ar.spaces.active;sp.shading.color_type='MATERIAL';sp.overlay.show_extras=False;sp.region_3d.view_distance=22
   sp.region_3d.view_location=(0,2,1.5);sp.region_3d.view_rotation=Vector((.22,-.9,.45)).to_track_quat('Z','Y')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Exotic-Crushers.blend'),compress=True)
studio.hide_render=False;S.camera=cam
rd=P/'renders';rd.mkdir(exist_ok=True);ic=O/'Icons';ic.mkdir(exist_ok=True)
for d in D.values():
 if os.environ.get('EXOTIC_ONLY') and d['id'] not in os.environ['EXOTIC_ONLY'].split(','):continue
 d['root'].location=(0,0,0)
 for dd in D.values():dd['col'].hide_render=dd is not d
 for t,label in [(1,''),(34,'-contact')]:
  S.frame_set(t);floor.hide_render=False;S.render.film_transparent=False
  S.render.resolution_x=660;S.render.resolution_y=520;S.render.filepath=str(rd/(d['id']+label+'.png'));bpy.ops.render.render(write_still=True)
 S.frame_set(1);floor.hide_render=True;S.render.film_transparent=True;cd.ortho_scale=5.4
 S.render.resolution_x=512;S.render.resolution_y=512;S.render.filepath=str(ic/('Crusher_'+d['id']+'.png'));bpy.ops.render.render(write_still=True)
 cd.ortho_scale=6.2

