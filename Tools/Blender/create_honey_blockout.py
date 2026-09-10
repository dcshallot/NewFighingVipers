"""Create the Honey P1 C2 blockout and fixed-view review renders in Blender 5.2.1."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[2]


def parse_script_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-blend", type=Path, default=REPO_ROOT / "LocalData/Generated/Honey/BlenderReplay/Honey_Blockout_v002.blend")
    parser.add_argument("--render-dir", type=Path, default=REPO_ROOT / "LocalData/Reviews/Honey/BlenderReplay/Blockout_v002")
    parser.add_argument("--force", action="store_true")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return parser.parse_known_args(argv)[0]


ARGS = parse_script_args()
BLEND_PATH = ARGS.output_blend.resolve()
RENDER_DIR = ARGS.render_dir.resolve()
ARCHIVED_V005 = (REPO_ROOT / "ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend").resolve()
if BLEND_PATH == ARCHIVED_V005:
    raise ValueError("The archived v005 evidence is immutable; choose another output path")
if BLEND_PATH.exists() and not ARGS.force:
    raise FileExistsError(f"Refusing to overwrite {BLEND_PATH}; pass --force")


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name: str, color: tuple[float, float, float, float], metallic: float = 0.0, roughness: float = 0.5):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return mat


def assign(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    obj.data.materials.append(mat)
    return obj


def smooth(obj: bpy.types.Object) -> None:
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = True


def uv_sphere(name: str, location, scale, mat, segments: int = 24, rings: int = 16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smooth(obj)
    return assign(obj, mat)


def cone(name: str, location, radius1: float, radius2: float, depth: float, mat, vertices: int = 24):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    smooth(obj)
    return assign(obj, mat)


def cube(name: str, location, scale, mat, rotation=(0.0, 0.0, 0.0), bevel: float = 0.02):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        modifier = obj.modifiers.new("BlockoutBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return assign(obj, mat)


def limb(name: str, start, end, radius_start: float, radius_end: float, mat, vertices: int = 16):
    start_v = Vector(start)
    end_v = Vector(end)
    delta = end_v - start_v
    midpoint = (start_v + end_v) / 2
    obj = cone(name, midpoint, radius_start, radius_end, delta.length, mat, vertices)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    return obj


def ellipsoid_between(name: str, start, end, radii_xy, mat):
    start_v = Vector(start)
    end_v = Vector(end)
    delta = end_v - start_v
    obj = uv_sphere(name, (start_v + end_v) / 2, (radii_xy[0], radii_xy[1], delta.length / 2), mat)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    return obj


def parent_all(root: bpy.types.Object) -> None:
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.parent is None and obj.type not in {"CAMERA", "LIGHT"} and obj.name != "ReviewGround":
            obj.parent = root


def build_character() -> bpy.types.Object:
    red = material("M_Honey_Blockout_Red", (0.445, 0.006, 0.012, 1.0), roughness=0.34)
    red_bright = material("M_Honey_Blockout_RedHighlight", (0.72, 0.012, 0.02, 1.0), roughness=0.26)
    black = material("M_Honey_Blockout_Black", (0.012, 0.017, 0.021, 1.0), roughness=0.42)
    hair = material("M_Honey_Blockout_Hair", (0.006, 0.008, 0.012, 1.0), roughness=0.38)
    white = material("M_Honey_Blockout_WarmWhite", (0.82, 0.78, 0.75, 1.0), roughness=0.62)
    skin = material("M_Honey_Blockout_Skin", (0.68, 0.37, 0.25, 1.0), roughness=0.58)
    silver = material("M_Honey_Blockout_Silver", (0.42, 0.45, 0.48, 1.0), metallic=0.65, roughness=0.28)

    root = bpy.data.objects.new("CHR_Honey_Blockout", None)
    bpy.context.collection.objects.link(root)
    root["stage"] = "C2_Blockout_v002"
    root["character_state"] = "P1_Normal"
    root["target_heads"] = 6.5
    root["reference_manifest"] = "Reference/Manifests/honey-p1-selected-views.csv"

    # Base anatomy: 1.72 m target height, deliberately long-legged stylized proportions.
    uv_sphere("CHR_Honey_Head", (0, -0.015, 1.585), (0.098, 0.092, 0.125), skin)
    cone("CHR_Honey_Neck", (0, 0.0, 1.445), 0.047, 0.043, 0.105, skin)
    uv_sphere("CHR_Honey_Torso", (0, 0.015, 1.215), (0.185, 0.118, 0.265), red)
    uv_sphere("CHR_Honey_Waist", (0, 0.012, 0.985), (0.138, 0.10, 0.145), black)
    uv_sphere("CHR_Honey_Hips", (0, 0.015, 0.88), (0.18, 0.12, 0.135), black)

    # Face proxy and eyes communicate facing direction without committing to final face design.
    uv_sphere("CHR_Honey_FacePlane", (0, -0.094, 1.58), (0.066, 0.021, 0.082), skin, 16, 12)
    for side in (-1, 1):
        uv_sphere(f"CHR_Honey_Eye_{side:+d}", (side * 0.036, -0.129, 1.585), (0.012, 0.006, 0.009), black, 12, 8)

    # Legs and black undersuit.
    for side in (-1, 1):
        hip = (side * 0.105, 0.012, 0.86)
        knee = (side * 0.13, 0.005, 0.53)
        ankle = (side * 0.13, -0.005, 0.17)
        ellipsoid_between(f"CHR_Honey_Thigh_{side:+d}", hip, knee, (0.085, 0.075), black)
        ellipsoid_between(f"CHR_Honey_Shin_{side:+d}", knee, ankle, (0.062, 0.057), black)

        # Boots: tall shin shell, pointed foot, heel, and front black inset.
        limb(f"CHR_Honey_BootShaft_{side:+d}", (side * 0.13, -0.004, 0.51), (side * 0.13, -0.008, 0.15), 0.09, 0.072, red_bright)
        cube(f"CHR_Honey_BootFoot_{side:+d}", (side * 0.13, -0.105, 0.095), (0.078, 0.17, 0.055), red_bright, rotation=(math.radians(8), 0, 0), bevel=0.035)
        cube(f"CHR_Honey_BootToe_{side:+d}", (side * 0.13, -0.255, 0.075), (0.066, 0.10, 0.035), red_bright, rotation=(math.radians(7), 0, 0), bevel=0.025)
        cube(f"CHR_Honey_Heel_{side:+d}", (side * 0.13, 0.015, 0.045), (0.028, 0.04, 0.075), red_bright, rotation=(math.radians(-10), 0, 0), bevel=0.012)
        cube(f"CHR_Honey_BootInset_{side:+d}", (side * 0.13, -0.086, 0.34), (0.035, 0.012, 0.13), black, bevel=0.012)
        # Angular knee flare.
        cone(f"CHR_Honey_KneeFlare_{side:+d}", (side * 0.13, -0.035, 0.535), 0.12, 0.055, 0.18, red_bright, 4).rotation_euler[1] = math.radians(90)

    # Skirt and belt. The lace uses a simplified warm-white ring for silhouette only.
    cone("CHR_Honey_Skirt", (0, 0.015, 0.92), 0.32, 0.16, 0.24, red, 32)
    cone("CHR_Honey_SkirtLace", (0, 0.015, 0.795), 0.342, 0.322, 0.045, white, 32)
    cone("CHR_Honey_Belt", (0, 0.005, 1.025), 0.19, 0.19, 0.075, black, 24)
    for x in (-0.105, 0, 0.105):
        cube(f"CHR_Honey_BeltBuckle_{x:+.2f}", (x, -0.176, 1.025), (0.035, 0.014, 0.028), silver, bevel=0.008)

    # Arms in a relaxed A pose.
    for side in (-1, 1):
        shoulder = (side * 0.245, 0.0, 1.31)
        elbow = (side * 0.46, -0.005, 1.12)
        wrist = (side * 0.59, -0.025, 0.94)
        hand = (side * 0.63, -0.045, 0.885)
        limb(f"CHR_Honey_UpperArm_{side:+d}", shoulder, elbow, 0.067, 0.055, skin)
        limb(f"CHR_Honey_Forearm_{side:+d}", elbow, wrist, 0.064, 0.048, black)
        ellipsoid_between(f"CHR_Honey_Gauntlet_{side:+d}", (side * 0.43, -0.005, 1.14), wrist, (0.073, 0.067), black)
        uv_sphere(f"CHR_Honey_Hand_{side:+d}", hand, (0.047, 0.035, 0.072), white, 16, 10)
        uv_sphere(f"CHR_Honey_ShoulderArmor_{side:+d}", (side * 0.225, 0.005, 1.34), (0.115, 0.105, 0.112), red_bright)
        cone(f"CHR_Honey_ArmBand_{side:+d}", (side * 0.345, -0.001, 1.225), 0.071, 0.071, 0.055, black, 16).rotation_euler[1] = math.radians(48 * side)
        uv_sphere(f"CHR_Honey_Cuff_{side:+d}", (side * 0.545, -0.025, 0.995), (0.085, 0.07, 0.065), white, 16, 10)

    # Hair cap, fringe, and two large rear spikes.
    uv_sphere("CHR_Honey_HairCap", (0, 0.015, 1.63), (0.11, 0.102, 0.132), hair)
    for index, x in enumerate((-0.065, -0.022, 0.025, 0.067)):
        spike = limb(f"CHR_Honey_Fringe_{index}", (x, -0.103, 1.64), (x * 1.25, -0.145, 1.49 + abs(x) * 0.25), 0.026, 0.006, hair, 8)
        spike.rotation_mode = "QUATERNION"
    for side in (-1, 1):
        limb(
            f"CHR_Honey_RearHair_{side:+d}",
            (side * 0.05, 0.085, 1.68),
            (side * 0.11, 0.29, 1.84),
            0.05,
            0.018,
            hair,
            10,
        )
        limb(
            f"CHR_Honey_RearHairTip_{side:+d}",
            (side * 0.11, 0.29, 1.84),
            (side * 0.18, 0.39, 1.76),
            0.035,
            0.005,
            hair,
            8,
        )
        # Head lace / wing proxy.
        wing = uv_sphere(f"CHR_Honey_HeadOrnament_{side:+d}", (side * 0.088, 0.055, 1.745), (0.05, 0.018, 0.074), white, 16, 10)
        wing.rotation_euler = (math.radians(15), math.radians(20 * side), math.radians(-25 * side))

    # Back harness, center spine and paired wing-like plates.
    cube("CHR_Honey_BackPanel", (0, 0.128, 1.19), (0.13, 0.035, 0.22), black, bevel=0.025)
    cube("CHR_Honey_BackSpine", (0, 0.169, 1.22), (0.025, 0.018, 0.23), white, bevel=0.008)
    for side in (-1, 1):
        cube(f"CHR_Honey_BackStrap_{side:+d}", (side * 0.11, 0.142, 1.18), (0.026, 0.017, 0.22), black, rotation=(0, 0, math.radians(-18 * side)), bevel=0.012)
        wing = uv_sphere(f"CHR_Honey_BackWing_{side:+d}", (side * 0.145, 0.19, 1.28), (0.082, 0.028, 0.165), white, 20, 12)
        wing.rotation_euler = (math.radians(-15), math.radians(28 * side), math.radians(-18 * side))
        cube(f"CHR_Honey_WingRoot_{side:+d}", (side * 0.10, 0.17, 1.29), (0.048, 0.03, 0.055), silver, bevel=0.012)

    parent_all(root)
    return root


def setup_review_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.035, 0.035, 0.045)

    ground_mat = material("M_ReviewGround", (0.12, 0.13, 0.15, 1.0), roughness=0.8)
    bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "ReviewGround"
    assign(ground, ground_mat)

    bpy.ops.object.light_add(type="AREA", location=(2.8, -3.5, 4.0))
    key = bpy.context.object
    key.name = "ReviewKey"
    key.data.energy = 1000
    key.data.shape = "DISK"
    key.data.size = 3.0
    key.rotation_euler = (math.radians(28), 0, math.radians(38))

    bpy.ops.object.light_add(type="AREA", location=(-3.0, -1.0, 2.4))
    fill = bpy.context.object
    fill.name = "ReviewFill"
    fill.data.energy = 650
    fill.data.size = 2.5
    fill.rotation_euler = (math.radians(70), 0, math.radians(-65))

    bpy.ops.object.light_add(type="AREA", location=(0, 3.0, 3.0))
    rim = bpy.context.object
    rim.name = "ReviewRim"
    rim.data.energy = 900
    rim.data.size = 2.0
    rim.rotation_euler = (math.radians(-35), 0, math.radians(180))

    bpy.ops.object.camera_add(location=(0, -6, 1.05))
    camera = bpy.context.object
    camera.name = "ReviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.18
    camera.data.lens = 70
    scene.camera = camera
    return camera


def point_camera(camera: bpy.types.Object, location, target=(0, 0, 0.95)) -> None:
    camera.location = location
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_views(camera: bpy.types.Object) -> None:
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    views = {
        "front": (0, -6, 1.05),
        "front_3q": (4.25, -4.25, 1.05),
        "right": (6, 0, 1.05),
        "back_3q": (4.25, 4.25, 1.05),
        "back": (0, 6, 1.05),
        "left": (-6, 0, 1.05),
    }
    for name, location in views.items():
        point_camera(camera, location)
        bpy.context.scene.render.filepath = str(RENDER_DIR / f"Honey_Blockout_v002_{name}.png")
        bpy.ops.render.render(write_still=True)


clear_scene()
character = build_character()
camera = setup_review_scene()
BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
render_views(camera)
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
print(f"Saved blockout: {BLEND_PATH}")
print(f"Rendered review views: {RENDER_DIR}")
