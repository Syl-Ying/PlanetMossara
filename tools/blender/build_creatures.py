"""Reproducible Blender creature sculpt, UV bake, rig and GLB export.
Run: Blender --background --factory-startup --python tools/blender/build_creatures.py
"""
import bpy, bmesh, math, os, random, json
from mathutils import Vector
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/creatures'
random.seed(1906)


def reset():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)


def mat(name, color, spotted=True):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color,1); m.use_nodes = True
    n=m.node_tree.nodes; l=m.node_tree.links; bs=n.get('Principled BSDF')
    bs.inputs['Roughness'].default_value=.88
    bs.inputs['Specular IOR Level'].default_value=.12
    bs.inputs['Base Color'].default_value=(*color,1)
    if spotted:
        tex=n.new('ShaderNodeTexNoise'); tex.inputs['Scale'].default_value=38; tex.inputs['Detail'].default_value=3
        coord=n.new('ShaderNodeTexCoord'); l.new(coord.outputs['Generated'],tex.inputs['Vector'])
        ramp=n.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].position=.60
        ramp.color_ramp.elements[0].color=(*color,1)
        ramp.color_ramp.elements[1].position=.73
        ramp.color_ramp.elements[1].color=(*(c*.62 for c in color),1)
        l.new(tex.outputs['Fac'],ramp.inputs[0]); l.new(ramp.outputs[0],bs.inputs['Base Color'])
    return m


def mesh(name, verts, faces, material):
    data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    ob=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(ob)
    ob.data.materials.append(material)
    for p in data.polygons:p.use_smooth=True
    return ob


def catmull(values, subdivisions=5):
    result=[]
    for i in range(len(values)-1):
        a=Vector(values[max(0,i-1)]); b=Vector(values[i]); c=Vector(values[i+1]); d=Vector(values[min(len(values)-1,i+2)])
        for j in range(subdivisions):
            t=j/subdivisions
            result.append(tuple(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)))
    result.append(values[-1]);return result


def tube(name, points, radii, material, segments=16, sub=5):
    samples=catmull([(*p,r) for p,r in zip(points,radii)],sub)
    vs=[]; fs=[]; previous_right=None
    for j,s in enumerate(samples):
        p=Vector(s[:3]); r=max(.001,s[3])
        tangent=Vector(samples[min(j+1,len(samples)-1)][:3])-Vector(samples[max(0,j-1)][:3]); tangent.normalize()
        axis=Vector((0,0,1)) if abs(tangent.z)<.92 else Vector((0,1,0))
        right=tangent.cross(axis).normalized() if previous_right is None else (previous_right-tangent*previous_right.dot(tangent)).normalized()
        previous_right=right.copy();up=tangent.cross(right).normalized()
        for i in range(segments):
            a=2*math.pi*i/segments
            vs.append(tuple(p+r*(right*math.cos(a)+up*math.sin(a))))
    for j in range(len(samples)-1):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments;fs.append((a,b,b+segments,a+segments))
    fs.append(tuple(reversed(range(segments))));fs.append(tuple((len(samples)-1)*segments+i for i in range(segments)))
    return mesh(name,vs,fs,material)


def body_loft(name, sections, material):
    samples=catmull(sections,6);vs=[];fs=[];n=40
    for y,z,w,h in samples:
        for i in range(n):
            a=2*math.pi*i/n
            vs.append((max(.008,w)*math.cos(a),y,z+max(.008,h)*math.sin(a)))
    for j in range(len(samples)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n;fs.append((a,a+n,b+n,b))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(samples)-1)*n+i for i in range(n)))
    return mesh(name,vs,fs,material)


def ellipsoid(name, center, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=center)
    ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(material)
    for p in ob.data.polygons:p.use_smooth=True
    return ob


def active(ob):
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob


def union_skin(parts,name):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();ob=parts[0];ob.name=name
    mod=ob.modifiers.new('Unified organic skin','REMESH');mod.mode='VOXEL';mod.voxel_size=.034;mod.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=ob.modifiers.new('Sculpt smoothing','SMOOTH');mod.factor=.62;mod.iterations=5;bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=ob.modifiers.new('Game surface reduction','DECIMATE');mod.ratio=.42;bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.data.validate(verbose=True)
    ob.data.update()
    for p in ob.data.polygons:p.use_smooth=True
    return ob


def bake_skin(ob, species):
    active(ob);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.018);bpy.ops.object.mode_set(mode='OBJECT')
    image=bpy.data.images.new(species+'_skin_albedo',width=1024,height=1024)
    for m in ob.data.materials:
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;m.node_tree.nodes.active=node
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8
    scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True
    scene.render.bake.margin=12
    bpy.ops.object.bake(type='DIFFUSE')
    image.filepath_raw=str(OUT/'textures'/f'{species}_skin_albedo.png');image.file_format='PNG';image.save();image.pack()
    for m in ob.data.materials:
        n=m.node_tree.nodes;bs=n.get('Principled BSDF');tex=next(x for x in n if x.type=='TEX_IMAGE' and x.image==image)
        m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    return image


def make_rig(name, legs, extra):
    data=bpy.data.armatures.new(name+'_skeleton');rig=bpy.data.objects.new(name+'_Rig',data);bpy.context.collection.objects.link(rig)
    active(rig);bpy.ops.object.mode_set(mode='EDIT')
    def bone(n,h,t,parent=None):
        b=data.edit_bones.new(n);b.head=h;b.tail=t
        if parent:b.parent=data.edit_bones[parent]
        return b
    bone('Root',(0,0,.35),(0,0,1.0))
    for n,h,t in extra:bone(n,h,t,'Root' if not n.startswith('Tail') or n=='Tail0' else 'Tail'+str(int(n[4:])-1))
    for n,points in legs:
        bone(n+'_Upper',points[0],points[1],'Root');bone(n+'_Lower',points[1],points[2],n+'_Upper');bone(n+'_Foot',points[2],points[3],n+'_Lower')
    bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
    return rig


def dist_segment(p,a,b):
    v=b-a;t=max(0,min(1,(p-a).dot(v)/max(1e-6,v.length_squared)));return (p-a-v*t).length


def bind_skin(ob,rig,legs,species):
    # Smooth distance weights; paired legs cannot pull the opposite side of the body.
    groups={b.name:ob.vertex_groups.new(name=b.name) for b in rig.data.bones}
    for v in ob.data.vertices:
        p=ob.matrix_world@v.co; candidates=[]
        for b in rig.data.bones:
            n=b.name
            if n.startswith('Frill'):continue
            if n.startswith('Leg'):
                side=1 if '_R_' in n else -1
                if p.x*side<.22:continue
                d=dist_segment(p,b.head_local,b.tail_local)
                if p.z>(1.75 if species=='pigoid' else .90):d+=.6
            elif n=='Head':
                d=dist_segment(p,b.head_local,b.tail_local)+(.8 if p.y>-.8 else 0)
            elif n.startswith('Tail'):
                if p.y<.8:continue
                d=dist_segment(p,b.head_local,b.tail_local)
            else:
                d=dist_segment(p,b.head_local,b.tail_local)
                if p.z<(1.1 if species=='pigoid' else .35):d+=.9
            candidates.append((d,n))
        candidates.sort();weights=[(1/max(.05,d)**5,n) for d,n in candidates[:3]];total=sum(w for w,n in weights)
        for w,n in weights:groups[n].add([v.index],w/total,'REPLACE')
    modifier=ob.modifiers.new('Skeletal deformation','ARMATURE');modifier.object=rig;ob.parent=rig


def rigid_bind(ob,rig,bone):
    group=ob.vertex_groups.new(name=bone);group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    mod=ob.modifiers.new('Follow skeleton','ARMATURE');mod.object=rig;ob.parent=rig


def animate(rig,legs,species):
    for clip in ['Idle','Walk','Feed' if species=='pigoid' else 'Alert']:
        rig.animation_data_create(); action=bpy.data.actions.new(clip);rig.animation_data.action=action
        for frame in range(1,62,5):
            phase=(frame-1)/60*math.tau
            for b in rig.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
            rig.pose.bones['Root'].location.z=.016*math.sin(phase)
            if clip=='Walk':
                for i,(n,_) in enumerate(legs):
                    step=phase+(i%2)*math.pi+(i//2)*.8
                    rig.pose.bones[n+'_Upper'].rotation_euler.x=.20*math.sin(step)
                    rig.pose.bones[n+'_Lower'].rotation_euler.x=.24*max(0,math.sin(step))
                    rig.pose.bones[n+'_Foot'].rotation_euler.x=-.10*math.sin(step)
            rig.pose.bones['Head'].rotation_euler.x=-.035*(1-math.cos(phase)) if clip=='Feed' else .018*math.sin(phase)
            if species=='sterq':
                for i in range(3):rig.pose.bones['Tail'+str(i)].rotation_euler.z=.075*math.sin(phase-i*.7)
                for side in ['L','R']:
                    rig.pose.bones['Frill_'+side].rotation_euler.y=(1 if side=='R' else -1)*(.12 if clip=='Alert' else .035)*math.sin(phase)
            for b in rig.pose.bones:
                b.keyframe_insert('rotation_euler',frame=frame,group=b.name);b.keyframe_insert('location',frame=frame,group=b.name)
        action.use_fake_user=True
        track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);track.mute=True
    rig.animation_data.action=None
    for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)


def pigoid():
    skin=mat('Pigoid_IvorySkin',(.64,.59,.46));plate=mat('SageDorsalPlates',(.27,.34,.28),False)
    hoof=mat('SplitHoof',(.065,.058,.075),False);dark=mat('RecessedEyes',(.018,.014,.022),False)
    crease=mat('PigoidCreases',(.31,.285,.235),False)
    blue=mat('SensoryAntennae',(.13,.27,.30),False);pink=mat('FeedingProboscis',(.42,.24,.20),False)
    sections=[(1.32,2.04,.02,.04),(1.12,2.06,.44,.53),(.65,2.03,.66,.70),(0,1.87,.62,.66),(-.6,1.64,.47,.55),(-1.12,1.29,.34,.41),(-1.62,.97,.24,.30),(-1.94,.78,.17,.21),(-2.04,.64,.035,.07)]
    parts=[body_loft('ContinuousPearBodyAndHead',sections,skin)];details=[];legs=[]
    for pair,y in enumerate([-.63,.14,.88]):
        for side in [-1,1]:
            n=f'Leg{pair}_'+('L' if side<0 else 'R')
            points=[(side*.43,y,1.88),(side*.65,y+.21,1.04),(side*.73,y-.05,.24),(side*.75,y-.17,.095)]
            legs.append((n,points));parts.append(tube(n,points,[.23,.12,.052,.075],skin))
            for toe in [-1,1]:
                ob=ellipsoid(n+'_Toe'+str(toe),(side*.75+toe*.052,y-.21,.085),(.065,.16,.085),hoof);details.append((ob,n+'_Foot'))
    body=union_skin(parts,'Pigoid_SculptedSkin');bake_skin(body,'pigoid')
    for n,points in legs:
        knee=Vector(points[1])
        for fold in range(2):
            pts=[tuple(knee+Vector((.116*math.cos(a),.116*math.sin(a),.032*(fold-.5)))) for a in [i*math.pi/8 for i in range(9)]]
            details.append((tube('KneeCrease',pts,[.004]*9,crease,6,2),n+'_Lower'))
    for i,(y,z,h) in enumerate([(-.63,2.08,.55),(-.05,2.40,.69),(.54,2.62,.79),(1.00,2.51,.69)]):
        verts=[];faces=[]
        # Convex leaf-shaped plates with a raised center ridge, not stacked spheres.
        outline=[(y-.31,z),(y-.26,z+h*.6),(y+.25,z+h),(y+.31,z+h*.24),(y+.20,z-.04)]
        verts=[(0,yy,zz) for yy,zz in outline]+[(.10,y,z+h*.38),(-.10,y,z+h*.38)]
        for j in range(5):faces.extend([(5,j,(j+1)%5),(6,(j+1)%5,j)])
        ob=mesh('DorsalPlate_'+str(i+1),verts,faces,plate)
        mod=ob.modifiers.new('Soft plate edges','BEVEL');mod.width=.035;mod.segments=3;active(ob);bpy.ops.object.modifier_apply(modifier=mod.name);details.append((ob,'Root'))
        for side in [-1,1]:
            details.append((tube('PlateCentralVein',[(side*.102,y-.18,z+.12),(side*.105,y+.01,z+h*.4),(side*.024,y+.21,z+h*.86)],[.006,.005,.002],crease,6,4),'Root'))
    mouth=tube('FlexibleProboscis',[(0,-1.94,.79),(0,-2.08,.48),(0,-2.13,.16),(0,-2.17,.075)],[.105,.070,.052,.075],pink);details.append((mouth,'Head'))
    for fold in range(5):
        z=.24+fold*.07
        pts=[(.068*math.cos(a),-2.10+.068*math.sin(a),z) for a in [i*math.tau/16 for i in range(17)]]
        details.append((tube('ProboscisFold',pts,[.003]*17,crease,6,1),'Head'))
    details.append((ellipsoid('FeedingPad',(0,-2.17,.065),(.095,.09,.035),hoof),'Head'))
    for side in [-1,1]:
        details.append((ellipsoid('EyeSocket',(side*.198,-1.70,1.01),(.040,.065,.050),hoof),'Head'))
        details.append((ellipsoid('Eye',(side*.223,-1.72,1.015),(.022,.034,.028),dark),'Head'))
        details.append((tube('Antenna',[(side*.14,-1.75,1.08),(side*.19,-1.70,1.44),(side*.27,-1.58,1.80),(side*.34,-1.46,2.0)],[.023,.018,.012,.004],blue,10),'Head'))
    rig=make_rig('Pigoid',legs,[('Head',(0,-.75,1.55),(0,-1.9,.75))]);bind_skin(body,rig,legs,'pigoid')
    for ob,bone in details:rigid_bind(ob,rig,bone)
    animate(rig,legs,'pigoid');return rig


def sterq():
    skin=mat('Sterq_PlumSkin',(.27,.22,.245));membrane=mat('WineSensoryMembrane',(.29,.105,.095),False)
    vein=mat('FrillVeins',(.12,.065,.073),False);claw=mat('DarkClaws',(.035,.03,.04),False);eye=mat('AmberEyes',(.65,.39,.11),False)
    sections=[(3.9,.38,.012,.012),(3.45,.37,.045,.05),(2.8,.32,.095,.12),(2.1,.36,.19,.20),(1.4,.52,.34,.32),(.65,.65,.48,.43),(-.10,.73,.45,.46),(-.55,1.0,.33,.46),(-.87,1.4,.23,.38),(-1.14,1.69,.21,.25),(-1.5,1.77,.21,.17),(-1.80,1.72,.08,.09),(-1.86,1.70,.009,.02)]
    parts=[body_loft('ContinuousBodyNeckTail',sections,skin)];legs=[];details=[]
    for pair,y in enumerate([-.35,.95]):
        for side in [-1,1]:
            n=f'Leg{pair}_'+('L' if side<0 else 'R')
            points=[(side*.32,y,.75),(side*.67,y+.12,.44),(side*.76,y-.22,.14),(side*.82,y-.44,.065)]
            legs.append((n,points));parts.append(tube(n,points,[.18,.12,.059,.07],skin))
            for toe in range(4):
                start=(side*.80+(toe-1.5)*.047,y-.38,.08);end=(start[0]+(toe-1.5)*.035,y-.65,.04)
                parts.append(tube(n+'_Digit'+str(toe),[start,end],[.026,.008],skin,10,4))
                details.append((ellipsoid('Claw',end,(.014,.05,.018),claw),n+'_Foot'))
    body=union_skin(parts,'Sterq_SculptedSkin');bake_skin(body,'sterq')
    for side in [-1,1]:
        name='Frill_'+('L' if side<0 else 'R');verts=[];faces=[];N=50;M=24
        def point(u,v):
            # Along neck height; v opens outward from the neck into the sensory fan.
            z=.65+u*1.29; y=-.42-u*.60+v*(.35+.22*math.sin(u*math.pi))
            width=(.26+.54*math.sin(u*math.pi*.86))*(1-.06*math.cos(u*math.pi*10))
            return (side*(.18+v*width),y,z+.10*v*math.sin(u*math.pi))
        for j in range(N+1):
            for i in range(M+1):verts.append(point(j/N,i/M))
        for j in range(N):
            for i in range(M):
                u=(j+.5)/N;v=(i+.5)/M
                if any(((u-h)/.036)**2+((v-.80)/.085)**2<1 for h in [.20,.40,.60,.80]):continue
                a=j*(M+1)+i;face=(a,a+1,a+M+2,a+M+1);faces.append(face if side>0 else tuple(reversed(face)))
        ob=mesh('SensoryMembrane_'+name,verts,faces,membrane)
        mod=ob.modifiers.new('Membrane thickness','SOLIDIFY');mod.thickness=.012;active(ob);bpy.ops.object.modifier_apply(modifier=mod.name);details.append((ob,name))
        for ray in range(6):
            u=.06+ray*.175; pts=[point(u*(.65+.35*v),v) for v in [0,.25,.5,.75,1]]
            details.append((tube('CartilageRay',pts,[.018,.014,.010,.007,.003],vein,8,4),name))
        pts=[point(j/20,1) for j in range(21)]
        details.append((tube('ScallopedMembraneRim',pts,[.008]*21,vein,8,2),name))
        details.append((ellipsoid('EyeSocket',(side*.195,-1.44,1.84),(.05,.058,.048),claw),'Head'))
        details.append((tube('MouthCrease',[(side*.06,-1.82,1.66),(side*.19,-1.61,1.65),(side*.20,-1.36,1.65)],[.004,.005,.002],vein,6,4),'Head'))
        details.append((ellipsoid('Nostril',(side*.10,-1.76,1.75),(.014,.025,.010),claw),'Head'))
        details.append((ellipsoid('AmberEye',(side*.224,-1.46,1.845),(.021,.031,.026),eye),'Head'))
    extra=[('Head',(0,-.4,.8),(0,-1.4,1.75)),('Frill_L',(-.18,-.5,.7),(-.5,-.9,1.8)),('Frill_R',(.18,-.5,.7),(.5,-.9,1.8)),('Tail0',(0,.9,.55),(0,1.9,.37)),('Tail1',(0,1.9,.37),(0,2.8,.32)),('Tail2',(0,2.8,.32),(0,3.9,.38))]
    rig=make_rig('Sterq',legs,extra);bind_skin(body,rig,legs,'sterq')
    for ob,bone in details:rigid_bind(ob,rig,bone)
    animate(rig,legs,'sterq');return rig


def export(species,rig):
    scene=bpy.context.scene;scene.frame_start=1;scene.frame_end=61;scene.render.fps=30
    scene.frame_set(1)
    bpy.context.preferences.filepaths.save_version=0
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                area.spaces.active.shading.type='MATERIAL'
                area.spaces.active.region_3d.view_distance=7.0
                area.spaces.active.region_3d.view_location=(0,0,1.2)
    # Keep a clean, editable source with packed UV texture, armature and all actions.
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source'/f'{species}.blend'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT/'models'/f'{species}.glb'),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_force_sampling=True,
        export_materials='EXPORT',export_yup=True)
    report={'species':species,'bones':len(rig.data.bones),'meshes':len([o for o in scene.objects if o.type=='MESH']),
        'triangles':sum(len(p.vertices)-2 for o in scene.objects if o.type=='MESH' for p in o.data.polygons),
        'actions':[a.name for a in bpy.data.actions if a.users>0]}
    (OUT/'models'/f'{species}_report.json').write_text(json.dumps(report,indent=2))
    print('CREATURE COMPLETE',report,flush=True)

for species,build in [('pigoid',pigoid),('sterq',sterq)]:
    reset();rig=build();export(species,rig)
