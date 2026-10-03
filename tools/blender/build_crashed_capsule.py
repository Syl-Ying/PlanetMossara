"""Build the crashed capsule from its turnaround reference. Blender 4.5+.
Editable parts, baked base color, a GLB and actual model renders are written to assets/spacecraft.
"""
import bpy, bmesh, math, random, json
import numpy as np
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/spacecraft'
random.seed(2040)
for p in ['source','models','textures']: (OUT/p).mkdir(exist_ok=True,parents=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def material(name,color,metal=0,rough=.8):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
 return m
ivory=material('Ceramic ivory',(0.63,.60,.51));dark=material('Burnt insulation',(.055,.061,.063));metal=material('Exposed titanium',(.20,.23,.23),.65,.66)
coral=material('Faded coral',(.50,.24,.17));glass=material('Blue black glazing',(.04,.095,.12),.48,.22);mud=material('Wet grey silt',(.18,.17,.155));cable=material('Cable rubber',(.035,.028,.024));silver=material('Worn edges',(.47,.46,.40),.5)
# Baked UV pigments remain portable to Godot instead of relying on Blender noise nodes.
w,h=2048,1024
u,v=np.meshgrid(np.linspace(0,1,w),np.linspace(0,1,h))
rng=np.random.default_rng(2040)
noise=rng.random((h,w));mottle=(np.sin(u*91+np.sin(v*52))*np.cos(v*57+u*15))*.024
rgb=np.zeros((h,w,4),dtype=np.float32);rgb[:,:,:3]=np.array([.67,.64,.55])[None,None,:]+mottle[:,:,None]+(noise[:,:,None]-.5)*.045;rgb[:,:,3]=1
# v wraps around circumference, zero is the underside; center is the roof.
burn=np.clip((np.abs(v-.5)-.26)*10+(noise-.5)*.4,0,1)
rgb[:,:,:3]=rgb[:,:,:3]*(1-burn[:,:,None]*.87)+np.array([.028,.031,.032])[None,None,:]*burn[:,:,None]
for low,high in [(.193,.24),(.744,.790)]:
 mask=(u>low)&(u<high)&(noise>.10)
 rgb[mask,:3]=rgb[mask,:3]*.22+np.array([.51,.24,.17])*.78
for i in range(230):
 x=random.randrange(w);y=random.randrange(h);length=random.randrange(3,37)
 rgb[max(0,y-1):y+1,x:min(w,x+length),:3]*=random.uniform(.3,.65)
img=bpy.data.images.new('Capsule weathered hull',width=w,height=h);img.pixels.foreach_set(rgb.ravel());img.filepath_raw=str(OUT/'textures/capsule_hull_albedo.png');img.file_format='PNG';img.save();img.pack()
paint=material('Weathered ceramic UV',(1,1,1));n=paint.node_tree.nodes.new('ShaderNodeTexImage');n.image=img;paint.node_tree.links.new(n.outputs['Color'],paint.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])

parts=[]
def mesh(name,verts,faces,mat,uvs=None):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat);parts.append(ob)
 if uvs:
  layer=data.uv_layers.new(name='HullUV')
  for poly in data.polygons:
   for li in poly.loop_indices:layer.data[li].uv=uvs[data.loops[li].vertex_index]
 return ob

def bevel(ob,width=.02):
 mod=ob.modifiers.new('Machined edge','BEVEL');mod.width=width;mod.segments=2
 mod=ob.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return ob

def cube(name,loc,scale,mat,edge=.02):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);ob=bpy.context.object;ob.name=name;ob.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);ob.data.materials.append(mat);parts.append(ob)
 if edge:bevel(ob,edge)
 return ob

def cylinder(name,loc,r,depth,mat,direction=(1,0,0),vertices=48):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc);ob=bpy.context.object;ob.name=name;ob.rotation_mode='QUATERNION';ob.rotation_quaternion=Vector(direction).to_track_quat('Z','Y');ob.data.materials.append(mat);parts.append(ob);bevel(ob,.008);return ob

def tube(name,points,r,mat):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=r;curve.bevel_resolution=2
 sp=curve.splines.new('POLY');sp.points.add(len(points)-1)
 for p,co in zip(sp.points,points):p.co=(*co,1)
 ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat);parts.append(ob);return ob

def ring(name,x,y,z,r,thick,mat):
 return tube(name,[(x,y+math.sin(t)*r,z+math.cos(t)*r) for t in np.linspace(0,2*math.pi,65)],thick,mat)

profile=[(-2.65,.50),(-2.50,.87),(-2.20,1.22),(-1.72,1.48),(-1.05,1.60),(.5,1.60),(1.50,1.46),(2.15,1.25),(2.40,1.14)]
def radius(x):return float(np.interp(x,[a for a,b in profile],[b for a,b in profile]))
def surface(x,t,offset=0):
 r=radius(x)+offset
 return (x,math.sin(t)*r,1.50+math.cos(t)*r*.91)
def hole(x,t):return ((x+.18)/.78)**2+((t-math.pi/2)/.53)**2<1
# Segmented shell with a real missing region on the left side.
xs=np.linspace(-2.65,2.40,41);ts=np.linspace(-math.pi,math.pi,65)
verts=[];faces=[];uv=[]
for i in range(len(xs)-1):
 for j in range(len(ts)-1):
  x=(xs[i]+xs[i+1])/2;t=(ts[j]+ts[j+1])/2
  if hole(x,t):continue
  # Gaps only at major panel boundaries; fine subdivisions remain continuous.
  gapx=.009 if i%5==0 else 0;gapt=.004 if j%8==0 else 0
  corners=[(xs[i]+gapx,ts[j]+gapt),(xs[i+1],ts[j]+gapt),(xs[i+1],ts[j+1]),(xs[i]+gapx,ts[j+1])]
  k=len(verts)
  for xx,tt in corners:verts.append(surface(xx,tt));uv.append(((xx+2.65)/5.05,(tt+math.pi)/(2*math.pi)))
  faces.append((k,k+1,k+2,k+3))
hull=mesh('Segmented ceramic shell with torn access aperture',verts,faces,paint,uv)
bm=bmesh.new();bm.from_mesh(hull.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001);bm.to_mesh(hull.data);bm.free()
for poly in hull.data.polygons:poly.use_smooth=True
solid=hull.modifiers.new('Shell thickness','SOLIDIFY');solid.thickness=.035
# Longitudinal seams and fasteners read in silhouette, not only as texture.
for t in [-2.4,-1.6,-.8,0,.8,2.4]:
 tube('Longitudinal panel gasket',[surface(x,t,.004) for x in np.linspace(-2.57,2.36,55)],.009,dark)
for x in [-1.75,-1.03,.5,1.51,2.13]:
 pts=[]
 for t in np.linspace(-math.pi,math.pi,129):
  if hole(x,t):
   if len(pts)>1:tube('Broken transverse gasket',pts,.008,dark)
   pts=[]
  else:pts.append(surface(x,t,.005))
 if len(pts)>1:tube('Transverse gasket',pts,.008,dark)
 for t in np.linspace(-math.pi,math.pi,17)[:-1]:
  if not hole(x,t):
   loc=surface(x,t,.013);cylinder('Flush panel fastener',loc,.025,.014,metal,(0,math.sin(t),math.cos(t)))
# Nose pressure bulkhead and escape hatch.
cylinder('Forward pressure bulkhead',(-2.652,0,1.50),.49,.06,dark)
cylinder('Circular escape hatch',(-2.694,0,1.45),.43,.06,ivory)
ring('Escape hatch gasket',-2.732,0,1.45,.415,.014,dark)
ring('Escape hatch outer rim',-2.716,0,1.45,.48,.025,metal)
for t in np.linspace(0,2*math.pi,9)[:-1]:
 cylinder('Hatch bolt',(-2.741,math.sin(t)*.35,1.45+math.cos(t)*.35),.022,.014,metal)
handle=cube('Hatch release lever',(-2.77,.15,1.48),(.06,.19,.05),metal)
# Three curved inset glazing panels, mounted on the nose's upper curvature.
def patch(name,x0,x1,t0,t1,off,mat):
 vs=[];fs=[]
 for i in range(7):
  for j in range(9):vs.append(surface(x0+(x1-x0)*i/6,t0+(t1-t0)*j/8,off))
 for i in range(6):
  for j in range(8):
   k=i*9+j;fs.append((k,k+9,k+10,k+1))
 return mesh(name,vs,fs,mat)
for idx,t in enumerate([-.57,0,.57]):
 patch('Window %d pressure rim'%idx,-2.48,-2.06,t-.22,t+.22,.035,metal)
 patch('Window %d dark gasket'%idx,-2.46,-2.08,t-.20,t+.20,.05,dark)
 patch('Window %d glass'%idx,-2.435,-2.105,t-.178,t+.178,.064,glass)
# Rear cluster: closed firewall, seven genuinely hollow nozzles.
cylinder('Rear firewall',(2.39,0,1.50),1.145,.10,dark)
ring('Rear collar',(2.45),0,1.50,1.13,.05,metal)
def nozzle(name,y,z,r,length):
 vs=[];fs=[]
 rows=[(2.44,r*.68),(2.51,r*.76),(2.44+length,r),(2.44+length,r*.78),(2.53,r*.50)]
 for x,rr in rows:
  for t in np.linspace(0,2*math.pi,49)[:-1]:vs.append((x,y+math.sin(t)*rr,z+math.cos(t)*rr))
 for row in range(4):
  for j in range(48):
   k=row*48+j;q=row*48+(j+1)%48;fs.append((k,q,q+48,k+48))
 ob=mesh(name,vs,fs,metal);bevel(ob,.009)
 cylinder(name+' dark throat',(2.50,y,z),r*.52,.01,dark)
 ring(name+' lip',2.44+length,y,z,r*.9,.025,dark)
nozzle('Main engine',0,1.50,.48,.50)
for i in range(6):
 t=i*math.pi/3;nozzle('RCS nozzle %d'%i,math.sin(t)*.80,1.50+math.cos(t)*.80,.25,.34)
# Open maintenance bay has recessed interior, equipment and ribs, not a black decal.
bay=cube('Recessed maintenance equipment',(-.18,1.03,1.48),(1.30,.12,1.20),dark)
for x in [-.75,-.40,-.05,.30,.52]:
 cube('Bay structural rib',(x,1.15,1.5),(.045,.20,1.20),metal)
for z in [1.05,1.28,1.50,1.73,1.95]:
 cube('Bay equipment rack',(-.18,1.21,z),(1.25,.12,.035),silver,.006)
for i in range(6):
 x=-.64+i*.21
 tube('Exposed hanging cable',[(x,1.38,2.08),(x+.04,1.54,1.66),(x-.08,1.67,1.04),(x+.03,1.66,.71),(x+.15,1.47,.93)],.013,coral if i%3==0 else cable)
# Torn lip around the cut-out, deliberately irregular.
pts=[]
for a in np.linspace(0,2*math.pi,65):
 x=-.18+.79*math.cos(a);t=math.pi/2+.535*math.sin(a);pts.append(surface(x,t,.015))
tube('Exposed torn aperture lip',pts,.022,metal)
lid=cube('Bent maintenance hatch',(-.65,1.95,1.55),(.80,.055,.98),ivory);lid.rotation_euler=(.18,-.26,-.42)
for z in [1.25,1.78]:tube('Torn hinge',[(-.83,1.46,z),(-1.00,1.68,z),(-.89,1.93,z)],.025,metal)
# Crumpled stabilizer fins and one broken landing strut.
for side in [-1,1]:
 vs=[(1.50,side*1.15,1.95),(2.30,side*1.0,1.90),(2.49,side*1.94,2.36),(2.02,side*2.06,2.51),(1.95,side*1.59,2.15)]
 fin=mesh('Bent rear stabilizer',vs,[(0,1,2,3,4)],ivory);so=fin.modifiers.new('Fin thickness','SOLIDIFY');so.thickness=.055;bevel(fin,.02)
 tube('Fin dark leading edge',[vs[0],vs[4],vs[3]],.018,dark)
for side in [-1,1]:
 tube('Damaged landing strut',[(1.3,side*.88,.55),(1.49,side*1.0,.27),(1.80,side*1.16,.16)],.07,metal)
 cube('Landing shoe',(1.82,side*1.16,.12),(.45,.32,.10),dark)
# Additional service latches and readable designation.
for x in [-1.05,.9,1.88]:
 for t in [-1.15,.50,2.25]:
  loc=surface(x,t,.028);ob=cube('Service latch',loc,(.14,.08,.04),metal,.012);ob.rotation_euler.x=-t
bpy.ops.object.text_add(location=(.64,1.545,1.91),rotation=(math.pi/2,0,math.pi));label=bpy.context.object;label.name='Hull designation LC-17';label.data.body='LC-17';label.data.size=.21;label.data.extrude=.001;label.data.materials.append(dark);parts.append(label)
# Parent spacecraft only; the editable crashed pose is a single transform.
bpy.ops.object.empty_add();root=bpy.context.object;root.name='CrashedCapsule'
for ob in parts:ob.parent=root
root.rotation_euler=(math.radians(12),math.radians(-4),math.radians(-8));root.location.z=-.12
# Grounded debris and silt base are separate editable/exported objects.
ship_parts=list(parts);parts=[]
bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=16,location=(0,0,-.11));mound=bpy.context.object;mound.name='Impact silt mound';mound.scale=(3.35,2.12,.22);mound.data.materials.append(mud);parts.append(mound)
for vertex in mound.data.vertices:
 a=math.atan2(vertex.co.y,vertex.co.x);f=1+.045*math.sin(a*9)+.025*math.sin(a*17)
 vertex.co.x*=f;vertex.co.y*=f
for poly in mound.data.polygons:poly.use_smooth=True
for i in range(24):
 a=random.uniform(0,math.tau);r=random.uniform(2,3.4)
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(math.cos(a)*r,math.sin(a)*r*.65,.015));ob=bpy.context.object;ob.name='Impact rubble';ob.scale=(random.uniform(.08,.30),random.uniform(.08,.22),random.uniform(.035,.12));ob.data.materials.append(dark if i%3 else mud);parts.append(ob)
for i,loc in enumerate([(-1.1,2.7,-.095),(1.3,2.65,-.09)]):
 ob=cube('Detached ceramic fragment',loc,(.73,.49,.06),ivory);ob.rotation_euler=(.12,.2,(-.4 if i else .5))
# Convert exportable curves/text, preserving named mesh objects and modifiers in blend.
for ob in ship_parts+parts:
 if ob.type in {'CURVE','FONT'}:
  bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH')
export_objects=ship_parts+parts+[root]
bpy.ops.object.select_all(action='DESELECT')
for ob in export_objects:ob.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.gltf(filepath=str(OUT/'models/crashed_capsule.glb'),export_format='GLB',use_selection=True,export_apply=True)
# A separate studio stage is excluded from export.
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.16));stage=bpy.context.object;stage.name='RENDER ONLY studio floor';stage.data.materials.append(material('Studio background',(.34,.365,.35)))
world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.62,.69,.73,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5
for loc,power,size in [((-4,3,8),1800,7),((2,-5,5),1200,6),((5,4,6),900,5)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(-8.2,10,6.0));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,1.05))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=9.0
scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.render.resolution_x=1440;scene.render.resolution_y=1080;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
# Save the useful viewing angle in the editable source.
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':
  area.spaces.active.region_3d.view_distance=10;area.spaces.active.region_3d.view_location=(0,0,1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source/crashed_capsule.blend'))
scene.render.filepath=str(OUT/'models/crashed_capsule_render.png');bpy.ops.render.render(write_still=True)
camera.location=(8,9,5);camera.rotation_euler=(Vector((0,0,1.1))-camera.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/'models/crashed_capsule_rear.png');bpy.ops.render.render(write_still=True)
summary={'mesh_objects':sum(o.type=='MESH' for o in export_objects),'triangles_before_modifiers':sum(len(p.vertices)-2 for o in export_objects if o.type=='MESH' for p in o.data.polygons),'hull_length_m':5.05,'length_with_engine_m':5.59,'design_reference':'concepts/crashed_capsule_blueprint.png','notes':'Script-modeled interpretation; studio stage excluded from GLB; impact base included; no runtime collision added.'}
(OUT/'models/model_report.json').write_text(json.dumps(summary,indent=2))
print('CAPSULE COMPLETE',summary)
