"""Build Honey P1 clothing/hair blockout on the validated MPFB anatomy base."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path
from typing import Callable

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[2]


def parse_script_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-blend", type=Path, default=REPO_ROOT / "LocalData/Generated/Honey/BlenderReplay/Honey_BaseBody_v003.blend")
    parser.add_argument("--output-blend", type=Path, default=REPO_ROOT / "LocalData/Generated/Honey/BlenderReplay/Honey_ClothingBlockout_v005.blend")
    parser.add_argument("--render-dir", type=Path, default=REPO_ROOT / "LocalData/Reviews/Honey/BlenderReplay/ClothingBlockout_v005")
    parser.add_argument("--force", action="store_true")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return parser.parse_known_args(argv)[0]


ARGS = parse_script_args()
SOURCE_BLEND = ARGS.source_blend.resolve()
OUTPUT_BLEND = ARGS.output_blend.resolve()
RENDER_DIR = ARGS.render_dir.resolve()
ARCHIVED_V005 = (REPO_ROOT / "ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend").resolve()
if OUTPUT_BLEND == ARCHIVED_V005:
    raise ValueError("The archived v005 evidence is immutable; choose another output path")
if OUTPUT_BLEND.exists() and not ARGS.force:
    raise FileExistsError(f"Refusing to overwrite {OUTPUT_BLEND}; pass --force")


def material(name: str, color, metallic: float = 0.0, roughness: float = 0.5):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = color
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    return mat


def remove_previous() -> None:
    prefixes = ("CLOTH_", "HAIR_", "ARMOR_", "ORN_", "BOOT_", "REVIEW_")
    for obj in list(bpy.data.objects):
        if obj.name.startswith(prefixes):
            bpy.data.objects.remove(obj, do_unlink=True)


def shell_from_human(
    human: bpy.types.Object,
    name: str,
    predicate: Callable[[Vector], bool],
    mat: bpy.types.Material,
    offset: float = 0.006,
    thickness: float = 0.006,
) -> bpy.types.Object:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = human.evaluated_get(depsgraph)
    source = evaluated.to_mesh()
    source.calc_loop_triangles()

    selected = [polygon for polygon in source.polygons if predicate(polygon.center)]
    vertex_indices = sorted({index for polygon in selected for index in polygon.vertices})
    remap = {old: new for new, old in enumerate(vertex_indices)}
    vertices = [source.vertices[index].co + source.vertices[index].normal * offset for index in vertex_indices]
    faces = [[remap[index] for index in polygon.vertices] for polygon in selected]
    evaluated.to_mesh_clear()

    if not faces:
        raise RuntimeError(f"No faces selected for {name}")
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    solidify = obj.modifiers.new("GarmentThickness", "SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 0.0
    return obj


def ring_mesh(name: str, rings, mat, segments: int = 64, phase: float = 0.0):
    vertices = []
    for ring_index, (z, radius_x, radius_y, pleat) in enumerate(rings):
        for index in range(segments):
            angle = 2 * math.pi * index / segments
            ripple = 1.0 + pleat * math.cos(8 * angle + phase)
            vertices.append((radius_x * ripple * math.cos(angle), radius_y * ripple * math.sin(angle), z))
    faces = []
    for ring_index in range(len(rings) - 1):
        start = ring_index * segments
        nxt = (ring_index + 1) * segments
        for index in range(segments):
            following = (index + 1) % segments
            faces.append((start + index, start + following, nxt + following, nxt + index))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    solidify = obj.modifiers.new("GarmentThickness", "SOLIDIFY")
    solidify.thickness = 0.008
    solidify.offset = 0.0
    bevel = obj.modifiers.new("GarmentEdgeSoftening", "BEVEL")
    bevel.width = 0.004
    bevel.segments = 2
    return obj


def ribbon(name: str, points, widths, mat, thickness: float = 0.01, facing_axis=(1, 0, 0)):
    axis = Vector(facing_axis).normalized()
    vertices = []
    for point, width in zip(points, widths):
        point_v = Vector(point)
        vertices.extend((point_v - axis * width / 2, point_v + axis * width / 2))
    faces = []
    for index in range(len(points) - 1):
        current = index * 2
        following = current + 2
        faces.append((current, current + 1, following + 1, following))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    solidify = obj.modifiers.new("RibbonThickness", "SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 0.0
    bevel = obj.modifiers.new("RibbonEdge", "BEVEL")
    bevel.width = thickness * 0.45
    bevel.segments = 3
    return obj


def shoulder_dome(name: str, side: int, mat):
    center = Vector((side * 0.265, -0.005, 1.36))
    axis = Vector((side, 0, 0))
    basis_y = Vector((0, 1, 0))
    basis_z = Vector((0, 0, 1))
    radial_segments = 12
    arc_segments = 28
    vertices = []
    for ring in range(radial_segments + 1):
        theta = (math.pi / 2) * ring / radial_segments
        for index in range(arc_segments):
            phi = 2 * math.pi * index / arc_segments
            point = center + axis * (0.105 * math.cos(theta))
            point += basis_y * (0.105 * math.sin(theta) * math.cos(phi))
            point += basis_z * (0.125 * math.sin(theta) * math.sin(phi))
            vertices.append(tuple(point))
    faces = []
    for ring in range(radial_segments):
        start = ring * arc_segments
        nxt = (ring + 1) * arc_segments
        for index in range(arc_segments):
            following = (index + 1) % arc_segments
            faces.append((start + index, start + following, nxt + following, nxt + index))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    solidify = obj.modifiers.new("ArmorThickness", "SOLIDIFY")
    solidify.thickness = 0.012
    bevel = obj.modifiers.new("ArmorEdge", "BEVEL")
    bevel.width = 0.006
    bevel.segments = 2
    return obj


def pointed_toe(name: str, side: int, mat):
    x = side * 0.105
    rings = [
        ((x, -0.205, 0.105), (0.072, 0.075)),
        ((x, -0.31, 0.095), (0.062, 0.048)),
        ((x, -0.405, 0.085), (0.025, 0.018)),
    ]
    segments = 16
    vertices = []
    for (cx, cy, cz), (rx, rz) in rings:
        for index in range(segments):
            angle = 2 * math.pi * index / segments
            vertices.append((cx + rx * math.cos(angle), cy, cz + rz * math.sin(angle)))
    faces = []
    for ring in range(len(rings) - 1):
        for index in range(segments):
            following = (index + 1) % segments
            a = ring * segments + index
            b = ring * segments + following
            c = (ring + 1) * segments + following
            d = (ring + 1) * segments + index
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def curve_tube(name: str, points, radii, mat, bevel_depth: float):
    curve = bpy.data.curves.new(f"{name}_Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 3
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 3
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, coordinate, radius in zip(spline.bezier_points, points, radii):
        point.co = coordinate
        point.radius = radius
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def add_clothing(human: bpy.types.Object) -> None:
    red = material("M_Honey_P1_Red", (0.55, 0.008, 0.014, 1.0), roughness=0.34)
    red_gloss = material("M_Honey_P1_RedGloss", (0.72, 0.012, 0.018, 1.0), roughness=0.24)
    black = material("M_Honey_BlackTeal", (0.012, 0.022, 0.026, 1.0), roughness=0.38)
    white = material("M_Honey_WarmWhite", (0.86, 0.83, 0.80, 1.0), roughness=0.58)
    silver = material("M_Honey_Silver", (0.46, 0.50, 0.54, 1.0), metallic=0.7, roughness=0.24)
    hair = material("M_Honey_Hair", (0.004, 0.008, 0.011, 1.0), roughness=0.36)
    skin = material("M_Honey_SkinNeutral", (0.58, 0.38, 0.30, 1.0), roughness=0.55)

    human.data.materials.clear()
    human.data.materials.append(skin)
    for polygon in human.data.polygons:
        polygon.material_index = 0

    shell_from_human(
        human,
        "CLOTH_Honey_Bodice",
        lambda c: abs(c.x) < 0.24 and 1.02 < c.z < 1.42,
        red,
        0.008,
        0.008,
    )
    shell_from_human(
        human,
        "CLOTH_Honey_Undersuit",
        lambda c: abs(c.x) < 0.29 and 0.72 < c.z <= 1.04,
        black,
        0.005,
        0.006,
    )

    ring_mesh(
        "CLOTH_Honey_Skirt",
        [
            (1.005, 0.185, 0.125, 0.00),
            (0.94, 0.225, 0.155, 0.025),
            (0.84, 0.31, 0.225, 0.055),
            (0.775, 0.35, 0.255, 0.075),
        ],
        red,
    )
    ring_mesh(
        "CLOTH_Honey_SkirtLace",
        [
            (0.79, 0.345, 0.25, 0.055),
            (0.75, 0.37, 0.27, 0.105),
            (0.725, 0.355, 0.26, 0.12),
        ],
        white,
        phase=math.pi / 8,
    )

    for side in (-1, 1):
        shell_from_human(
            human,
            f"ARMOR_Honey_Shoulder_{side:+d}",
            lambda c, side=side: side * c.x > 0.17 and 1.25 < c.z < 1.48,
            red_gloss,
            0.016,
            0.014,
        )
        shell_from_human(
            human,
            f"ARMOR_Honey_Gauntlet_{side:+d}",
            lambda c, side=side: side * c.x > 0.29 and 0.86 < c.z < 1.24,
            black,
            0.012,
            0.014,
        )
        curve_tube(
            f"ORN_Honey_Cuff_{side:+d}",
            [(side * 0.43, -0.005, 1.06), (side * 0.48, -0.015, 1.00)],
            [1.0, 0.8],
            white,
            0.034,
        )
        shell_from_human(
            human,
            f"BOOT_Honey_Shaft_{side:+d}",
            lambda c, side=side: side * c.x > 0.035 and -0.01 < c.z < 0.57,
            red_gloss,
            0.012,
            0.014,
        )
        curve_tube(
            f"BOOT_Honey_Heel_{side:+d}",
            [(side * 0.105, 0.035, 0.105), (side * 0.105, 0.045, 0.025)],
            [0.55, 0.20],
            red_gloss,
            0.022,
        )

    # Chest and belt layering.
    ribbon("ORN_Honey_ChestPanel", [(0, -0.19, 1.09), (0, -0.20, 1.37)], [0.10, 0.13], black, 0.012)
    ring_mesh("ORN_Honey_Belt", [(1.02, 0.19, 0.13, 0), (0.98, 0.19, 0.13, 0)], black, 48)
    for x in (-0.105, 0, 0.105):
        bpy.ops.mesh.primitive_cube_add(location=(x, -0.142, 1.005), scale=(0.032, 0.014, 0.024))
        buckle = bpy.context.object
        buckle.name = f"ORN_Honey_Buckle_{x:+.2f}"
        buckle.data.materials.append(silver)
        bevel = buckle.modifiers.new("BuckleEdge", "BEVEL")
        bevel.width = 0.007
        bevel.segments = 2

    # Hair cap follows head curvature; face is excluded by y cutoff.
    shell_from_human(
        human,
        "HAIR_Honey_Cap",
        lambda c: c.z > 1.48 and c.y > -0.075,
        hair,
        0.014,
        0.012,
    )
    fringe_specs = [(-0.07, 1.65, 1.50), (-0.025, 1.68, 1.52), (0.025, 1.68, 1.52), (0.07, 1.65, 1.50)]
    for index, (x, top, bottom) in enumerate(fringe_specs):
        ribbon(
            f"HAIR_Honey_Fringe_{index}",
            [(x * 0.7, -0.105, top), (x, -0.14, (top + bottom) / 2), (x * 1.15, -0.135, bottom)],
            [0.052, 0.045, 0.012],
            hair,
            0.008,
        )

    for side in (-1, 1):
        curve_tube(
            f"HAIR_Honey_RearLockUpper_{side:+d}",
            [(side * 0.045, 0.07, 1.61), (side * 0.09, 0.16, 1.70), (side * 0.15, 0.26, 1.73), (side * 0.21, 0.34, 1.66)],
            [1.0, 1.15, 0.82, 0.18],
            hair,
            0.042,
        )
        curve_tube(
            f"HAIR_Honey_RearLockLower_{side:+d}",
            [(side * 0.04, 0.075, 1.59), (side * 0.085, 0.17, 1.60), (side * 0.14, 0.25, 1.54), (side * 0.18, 0.32, 1.46)],
            [0.9, 1.0, 0.65, 0.15],
            hair,
            0.034,
        )
        curve_tube(
            f"ORN_Honey_HeadWing_{side:+d}",
            [(side * 0.07, 0.045, 1.66), (side * 0.11, 0.075, 1.73), (side * 0.15, 0.10, 1.68)],
            [0.65, 1.0, 0.15],
            white,
            0.022,
        )
        curve_tube(
            f"ORN_Honey_BackWingMain_{side:+d}",
            [(side * 0.085, 0.16, 1.34), (side * 0.15, 0.21, 1.42), (side * 0.21, 0.25, 1.35)],
            [0.55, 1.0, 0.18],
            white,
            0.032,
        )
        curve_tube(
            f"ORN_Honey_BackWingLower_{side:+d}",
            [(side * 0.08, 0.16, 1.26), (side * 0.14, 0.21, 1.20), (side * 0.20, 0.24, 1.14)],
            [0.5, 0.85, 0.15],
            white,
            0.026,
        )
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, location=(side * 0.09, 0.17, 1.30), scale=(0.045, 0.03, 0.052))
        root = bpy.context.object
        root.name = f"ORN_Honey_WingRoot_{side:+d}"
        root.data.materials.append(silver)


def setup_review() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.018, 0.022, 0.028)

    ground = bpy.data.objects.get("ReviewGround")
    if ground is None:
        ground_mat = material("M_ReviewGround", (0.08, 0.09, 0.11, 1.0), roughness=0.85)
        bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, 0))
        ground = bpy.context.object
        ground.name = "ReviewGround"
        ground.data.materials.append(ground_mat)

    for obj in list(bpy.data.objects):
        if obj.type in {"LIGHT", "CAMERA"}:
            bpy.data.objects.remove(obj, do_unlink=True)
    for name, location, energy, size in (
        ("REVIEW_Key", (2.8, -3.8, 4.2), 1050, 3.0),
        ("REVIEW_Fill", (-3.2, -1.5, 2.5), 650, 2.8),
        ("REVIEW_Rim", (0, 3.3, 3.1), 1000, 2.2),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.rotation_euler = (Vector((0, 0, 1.0)) - light.location).to_track_quat("-Z", "Y").to_euler()

    bpy.ops.object.camera_add(location=(0, -6, 1.0))
    camera = bpy.context.object
    camera.name = "REVIEW_Camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.08
    scene.camera = camera
    return camera


def render_views(camera: bpy.types.Object) -> None:
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    views = {
        "front": (0, -6, 1.0),
        "front_3q": (4.25, -4.25, 1.0),
        "right": (6, 0, 1.0),
        "back_3q": (4.25, 4.25, 1.0),
        "back": (0, 6, 1.0),
        "left": (-6, 0, 1.0),
    }
    for name, location in views.items():
        camera.location = location
        camera.rotation_euler = (Vector((0, 0, 0.93)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        bpy.context.scene.render.filepath = str(RENDER_DIR / f"Honey_ClothingBlockout_v005_{name}.png")
        bpy.ops.render.render(write_still=True)


if not SOURCE_BLEND.is_file():
    raise FileNotFoundError(SOURCE_BLEND)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE_BLEND))
human = bpy.data.objects.get("CHR_Honey_MPFBase")
if human is None:
    raise RuntimeError("Validated MPFB human not found")
remove_previous()
add_clothing(human)
human["stage"] = "C2_ClothingBlockout_v005"
human["review_note"] = "MPFB anatomy with editable Honey P1 clothing and silhouette blockout"
camera = setup_review()
OUTPUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_BLEND))
render_views(camera)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_BLEND))
print(f"Saved clothing blockout: {OUTPUT_BLEND}")
print(f"Objects: {len(bpy.data.objects)}")
print(f"Rendered review views: {RENDER_DIR}")
