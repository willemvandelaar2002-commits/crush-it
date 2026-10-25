"""Deterministic model portraits. Python 3, numpy, Pillow.
python render_icons.py geometry.json --out assets/crusher-icons
Render-only bevels, consistent lighting and outline; no game model edits.
"""
import argparse,itertools,json,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter

def unit(v): return v/np.maximum(np.linalg.norm(v,axis=-1,keepdims=True),1e-12)
def primitive(p):
 size=np.array(p['size']);vertices=[];faces=[];smooth=False
 if p['kind']=='WedgePart':
  vertices=np.array([[x,y,z] for x in [-.5,.5] for y,z in [(-.5,-.5),(-.5,.5),(.5,.5)]])*size
  faces=[[0,2,1],[3,4,5],[0,1,4,3],[1,2,5,4],[2,0,3,5]]
 elif 'Ball' in p['shape']:
  smooth=True
  for row in range(17):
   t=math.pi*row/16
   for col in range(24):
    a=2*math.pi*col/24;vertices.append([math.sin(t)*math.cos(a),math.cos(t),math.sin(t)*math.sin(a)])
  for row in range(16):
   for col in range(24):
    a=row*24+col;b=row*24+(col+1)%24;faces.append([a,b,b+24,a+24])
  vertices=np.array(vertices)*size/2
 elif 'Cylinder' in p['shape']:
  n=32
  for end in [-1,1]:
   for col in range(n):
    a=2*math.pi*col/n;vertices.append([end*size[0]/2,math.cos(a)*size[1]/2,math.sin(a)*size[2]/2])
  faces=[list(reversed(range(n))),list(range(n,2*n))]
  for i in range(n):j=(i+1)%n;faces.append([i,j,j+n,i+n])
  vertices=np.array(vertices)
 else:
  half=size/2;bevel=min(.065,float(min(size))*.12);ix={}
  for signs in itertools.product([-1,1],repeat=3):
   for axis in range(3):
    v=np.array(signs)*(half-bevel);v[axis]=signs[axis]*half[axis];ix[signs,axis]=len(vertices);vertices.append(v)
  for axis in range(3):
   others=[i for i in range(3) if i!=axis]
   for sign in [-1,1]:
    face=[]
    for u,v in [(-1,-1),(-1,1),(1,1),(1,-1)]:
     s=[0,0,0];s[axis]=sign;s[others[0]]=u;s[others[1]]=v;face.append(ix[tuple(s),axis])
    faces.append(face)
  for a,b in [(0,1),(0,2),(1,2)]:
   c=3-a-b
   for sa,sb in itertools.product([-1,1],repeat=2):
    s=[0,0,0];s[a]=sa;s[b]=sb;s[c]=-1;lo=tuple(s);s[c]=1;hi=tuple(s);faces.append([ix[lo,a],ix[lo,b],ix[hi,b],ix[hi,a]])
  for s in itertools.product([-1,1],repeat=3):faces.append([ix[s,i] for i in range(3)])
  vertices=np.array(vertices)
 local=vertices.copy();rot=np.array(p['rotation']).reshape(3,3);center=np.array(p['position']);vertices=vertices@rot.T+center;result=[]
 for f in faces:
  for i in range(1,len(f)-1):
   ids=[f[0],f[i],f[i+1]];pts=vertices[ids];n=np.cross(pts[1]-pts[0],pts[2]-pts[0])
   if np.linalg.norm(n)<1e-10:continue
   n=unit(n)
   if np.dot(n,pts.mean(0)-center)<0:n=-n
   normals=unit(local[ids]/np.maximum(size/2,1e-8))@rot.T if smooth else np.tile(n,(3,1))
   result.append((pts,normals))
 return result

def render(model,out):
 resolution=1024;view=unit(np.array([.72,.52,1.]));right=unit(np.cross([0.,1.,0.],view));up=np.cross(view,right);basis=np.array([right,up,view]).T;entries=[]
 for p in model['parts']:
  for pts,n in primitive(p):
   if np.dot(n.mean(0),view)>-.05:entries.append((pts@basis,n,p))
 allpts=np.concatenate([e[0] for e in entries]);lo=allpts[:,:2].min(0);hi=allpts[:,:2].max(0);center=(lo+hi)/2;scale=resolution*.83/max(hi-lo)
 depth=np.full((resolution,resolution),-np.inf);pixels=np.zeros((resolution,resolution,3),dtype=np.float32)
 key=unit(np.array([-.6,1.1,1.4]));fill=unit(np.array([1.,.3,.5]));hl=unit(key+view)
 for points,normals,p in entries:
  screen=(points[:,:2]-center)*scale;screen[:,0]+=resolution/2;screen[:,1]=resolution/2-screen[:,1]
  xmin,ymin=np.maximum(np.floor(screen.min(0)).astype(int),0);xmax,ymax=np.minimum(np.ceil(screen.max(0)).astype(int),resolution-1)
  if xmin>xmax or ymin>ymax:continue
  a,b,c=screen;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-8:continue
  yy,xx=np.mgrid[ymin:ymax+1,xmin:xmax+1];w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w2=1-w0-w1
  z=w0*points[0,2]+w1*points[1,2]+w2*points[2,2];target=depth[ymin:ymax+1,xmin:xmax+1];mask=(w0>=-1e-7)&(w1>=-1e-7)&(w2>=-1e-7)&(z>target)
  if not mask.any():continue
  weights=np.stack([w0[mask],w1[mask],w2[mask]],axis=1);normal=unit(weights@normals);diff=.75+.35*np.maximum(normal@key,0)+.10*np.maximum(normal@fill,0);spec=np.maximum(normal@hl,0)**24*.30
  color=np.array(p['color']);grey=np.dot(color,[.2126,.7152,.0722]);color=np.clip(grey+(color-grey)*1.12,0,1);shaded=color[None,:]*diff[:,None]+spec[:,None]*(.45+color[None,:]*.55)
  if 'Neon' in p['material']:shaded=shaded*.5+color[None,:]*.5
  pixels[ymin:ymax+1,xmin:xmax+1][mask]=np.clip(shaded,0,1);target[mask]=z[mask]
 hit=np.isfinite(depth);ao=np.zeros_like(depth)
 for dy,dx in [(0,5),(0,-5),(5,0),(-5,0),(7,7),(-7,-7)]:
  near=np.roll(depth,(dy,dx),(0,1));delta=near-np.where(hit,depth,0);ao+=np.where(hit&np.isfinite(near)&(delta>.04)&(delta<.6),.035,0)
 pixels*=1-ao[:,:,None];alpha=Image.fromarray((hit*255).astype('uint8'));border=alpha.filter(ImageFilter.MaxFilter(23))
 result=Image.new('RGBA',(resolution,resolution),(19,23,42,0));result.putalpha(border);rgb=Image.fromarray(np.uint8(np.clip(pixels*255,0,255))).convert('RGBA');rgb.putalpha(alpha)
 out.parent.mkdir(parents=True,exist_ok=True);Image.alpha_composite(result,rgb).resize((512,512),Image.Resampling.LANCZOS).save(out)
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('geometry',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 for m in json.loads(a.geometry.read_text()):render(m,a.out/('Crusher_'+m['id']+'.png'));print(m['id'],flush=True)
