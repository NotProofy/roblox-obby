"""
Generates low-poly props for Red Line Challenge and exports each one as an FBX
that Roblox Studio's 3D Importer can read.

Run (from this folder, Blender 3.6+ or 4.x):
    blender --background --python make_assets.py

Output: blender/export/*.fbx
Or open Blender > Scripting tab > Open this file > Run Script.
"""
import math
import os

import bpy

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "export")
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in (bpy.data.meshes, bpy.data.materials):
        for item in list(block):
            block.remove(item)


def material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.6
    return mat


def paint(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return obj


def cube(size, location, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return paint(obj, mat)


def cylinder(radius, depth, location, mat, rotation=(0, 0, 0), vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    return paint(bpy.context.active_object, mat)


def join_and_export(name):
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    obj.location = (0, 0, 0)
    path = os.path.join(OUT_DIR, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, object_types={"MESH"})
    print("Exported", path)


def make_dumbbell():
    clear_scene()
    metal = material("Metal", (0.75, 0.75, 0.78))
    black = material("Rubber", (0.05, 0.05, 0.05))
    side = (0, math.pi / 2, 0)
    cylinder(0.08, 1.0, (0, 0, 0), metal, side)
    for x in (-0.45, 0.45):
        cylinder(0.28, 0.18, (x, 0, 0), black, side, vertices=6)
    join_and_export("Dumbbell")


def make_money_bag():
    clear_scene()
    green = material("BagGreen", (0.15, 0.55, 0.2))
    tan = material("Rope", (0.8, 0.65, 0.4))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.5, location=(0, 0, 0.45))
    body = paint(bpy.context.active_object, green)
    body.scale = (1, 1, 0.9)
    bpy.ops.object.transform_apply(scale=True)
    cylinder(0.14, 0.12, (0, 0, 0.92), tan, vertices=8)
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.05, radius2=0.25, depth=0.25, location=(0, 0, 1.08))
    paint(bpy.context.active_object, green)
    join_and_export("MoneyBag")


def make_treadmill():
    clear_scene()
    dark = material("Frame", (0.12, 0.12, 0.14))
    belt = material("Belt", (0.02, 0.02, 0.02))
    screen = material("Screen", (0.1, 0.5, 0.9))
    cube((1.4, 3.2, 0.3), (0, 0, 0.15), dark)
    cube((1.1, 3.0, 0.08), (0, 0, 0.34), belt)
    for x in (-0.62, 0.62):
        cube((0.08, 0.08, 1.4), (x, -1.4, 1.0), dark)
        cube((0.08, 0.8, 0.08), (x, -1.05, 1.3), dark)
    cube((1.3, 0.12, 0.5), (0, -1.45, 1.75), dark)
    cube((0.9, 0.02, 0.3), (0, -1.38, 1.78), screen)
    join_and_export("Treadmill")


def make_bench():
    clear_scene()
    pad = material("Pad", (0.1, 0.1, 0.45))
    metal = material("Metal", (0.6, 0.6, 0.62))
    black = material("Rubber", (0.05, 0.05, 0.05))
    cube((0.6, 2.0, 0.15), (0, 0, 0.55), pad)
    for y in (-0.8, 0.8):
        cube((0.08, 0.08, 0.5), (0, y, 0.25), metal)
        cube((0.6, 0.08, 0.06), (0, y, 0.03), metal)
    for x in (-0.6, 0.6):
        cube((0.08, 0.08, 1.2), (x, -0.85, 0.6), metal)
    cylinder(0.03, 2.2, (0, -0.85, 1.15), metal, (0, math.pi / 2, 0))
    for x in (-0.95, 0.95):
        cylinder(0.3, 0.08, (x, -0.85, 1.15), black, (0, math.pi / 2, 0), vertices=10)
    join_and_export("Bench")


def make_hoop():
    clear_scene()
    metal = material("Pole", (0.35, 0.35, 0.38))
    white = material("Board", (0.95, 0.95, 0.95))
    orange = material("Rim", (1.0, 0.4, 0.0))
    cylinder(0.1, 3.4, (0, 0, 1.7), metal)
    cube((0.12, 0.6, 0.12), (0, 0.25, 3.3), metal)
    cube((1.8, 0.06, 1.1), (0, 0.55, 3.4), white)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.28, minor_radius=0.025, location=(0, 0.88, 3.05))
    paint(bpy.context.active_object, orange)
    join_and_export("Hoop")


if __name__ == "__main__":
    make_dumbbell()
    make_money_bag()
    make_treadmill()
    make_bench()
    make_hoop()
    print("All assets exported to", OUT_DIR)
