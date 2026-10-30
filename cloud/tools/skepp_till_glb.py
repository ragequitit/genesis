# Gor om Quaternius-rymdskepp (FBX + stor PNG) till sma GLB med 256 px WebP-bild for 3D-varlden.
# Kors: blender -b --python cloud/tools/skepp_till_glb.py -- <kalla-mapp> <ut-mapp> Namn_Farg ...
import bpy, sys, os

argv = sys.argv[sys.argv.index('--') + 1:]
src, out, ships = argv[0], argv[1], argv[2:]
os.makedirs(out, exist_ok=True)

for item in ships:
    name, color = item.split('_')
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(src, name, 'FBX', name + '.fbx'))
    img = bpy.data.images.load(os.path.join(src, name, 'Textures', f'{name}_{color}.png'))
    img.scale(256, 256)
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH':
            continue
        for slot in ob.material_slots:
            m = slot.material
            if not m:
                continue
            m.use_nodes = True
            nt = m.node_tree
            bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if not bsdf:
                continue
            tex = next((n for n in nt.nodes if n.type == 'TEX_IMAGE'), None) or nt.nodes.new('ShaderNodeTexImage')
            tex.image = img
            nt.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
            bsdf.inputs['Alpha'].default_value = 1.0
            m.blend_method = 'OPAQUE' if hasattr(m, 'blend_method') else None
    bpy.ops.export_scene.gltf(filepath=os.path.join(out, 'ship_' + name.lower() + '.glb'), export_format='GLB',
                              export_image_format='WEBP', export_animations=False, export_apply=True)
    print('SKEPP OK', name, os.path.getsize(os.path.join(out, 'ship_' + name.lower() + '.glb')))
