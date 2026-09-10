"""Create the MPFB-based Honey P1 C2 anatomy base and fixed-view renders."""

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
    parser.add_argument("--output-blend", type=Path, default=REPO_ROOT / "LocalData/Generated/Honey/BlenderReplay/Honey_BaseBody_v003.blend")
    parser.add_argument("--render-dir", type=Path, default=REPO_ROOT / "LocalData/Reviews/Honey/BlenderReplay/BaseBody_v003")
    parser.add_argument("--mpfb-module", default="bl_ext.user_default.mpfb")
    parser.add_argument("--force", action="store_true")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return parser.parse_known_args(argv)[0]


ARGS = parse_script_args()
BLEND_PATH = ARGS.output_blend.resolve()
RENDER_DIR = ARGS.render_dir.resolve()
MPFB_MODULE = ARGS.mpfb_module
ARCHIVED_V005 = (REPO_ROOT / "ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend").resolve()
if BLEND_PATH == ARCHIVED_V005:
    raise ValueError("The archived v005 evidence is immutable; choose another output path")
if BLEND_PATH.exists() and not ARGS.force:
    raise FileExistsError(f"Refusing to overwrite {BLEND_PATH}; pass --force")


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def make_material(name: str, color, metallic: float = 0.0, roughness: float = 0.5):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = color
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    return mat


def add_cube(name: str, location, scale, mat, bevel: float = 0.02):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("ReviewBevel", "BEVEL")
    modifier.width = bevel
    modifier.segments = 2
    obj.data.materials.append(mat)
    return obj


def create_mpfb_human() -> bpy.types.Object:
    bpy.ops.preferences.addon_enable(module=MPFB_MODULE)
    result = bpy.ops.mpfb.create_human()
    if "FINISHED" not in result:
        raise RuntimeError(f"MPFB create_human failed: {result}")

    human = bpy.context.active_object
    if human is None or human.type != "MESH":
        human = bpy.data.objects.get("Human")
    if human is None or human.type != "MESH":
        raise RuntimeError("MPFB did not create a Human mesh")

    bpy.context.view_layer.objects.active = human
    human.select_set(True)
    scene = bpy.context.scene
    scene.mpfb_macropanel_gender = 0.0
    scene.mpfb_macropanel_age = 0.48
    scene.mpfb_macropanel_muscle = 0.38
    scene.mpfb_macropanel_weight = 0.42
    scene.mpfb_macropanel_height = 0.62
    scene.mpfb_macropanel_proportions = 0.38
    scene.mpfb_macropanel_cupsize = 0.40
    scene.mpfb_macropanel_firmness = 0.58
    scene.mpfb_macropanel_african = 0.18
    scene.mpfb_macropanel_asian = 0.55
    scene.mpfb_macropanel_caucasian = 0.27
    bpy.context.view_layer.update()

    human.name = "CHR_Honey_MPFBase"
    human["stage"] = "C2_BaseBody_v003"
    human["character_state"] = "P1_Normal"
    human["generator"] = "MPFB 2.0.17"
    human["generator_package_sha256"] = "4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87"
    human["core_asset_license"] = "CC0-1.0"
    human["reference_manifest"] = "Reference/Manifests/honey-p1-selected-views.csv"
    human["review_note"] = "Neutral anatomy base; no final face, clothing, topology, or material"

    mannequin = make_material("M_Honey_AnatomyBase", (0.39, 0.42, 0.46, 1.0), roughness=0.62)
    coverage = make_material("M_Honey_CoverageGuide", (0.08, 0.09, 0.11, 1.0), roughness=0.7)
    human.data.materials.clear()
    human.data.materials.append(mannequin)
    human.data.materials.append(coverage)
    for polygon in human.data.polygons:
        center = polygon.center
        torso_coverage = abs(center.x) < 0.24 and 1.02 < center.z < 1.43
        hip_coverage = abs(center.x) < 0.28 and 0.77 < center.z <= 1.02
        polygon.material_index = 1 if torso_coverage or hip_coverage else 0
        polygon.use_smooth = True

    human.select_set(True)
    bpy.context.view_layer.objects.active = human
    return human


def setup_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.022, 0.025, 0.032)

    ground_mat = make_material("M_ReviewGround", (0.09, 0.10, 0.12, 1.0), roughness=0.82)
    bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "ReviewGround"
    ground.data.materials.append(ground_mat)

    for name, light_type, location, energy, size in (
        ("ReviewKey", "AREA", (2.7, -3.8, 4.2), 950, 3.0),
        ("ReviewFill", "AREA", (-3.0, -1.2, 2.6), 600, 2.7),
        ("ReviewRim", "AREA", (0, 3.2, 3.2), 900, 2.2),
    ):
        bpy.ops.object.light_add(type=light_type, location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        direction = Vector((0, 0, 1.0)) - light.location
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    bpy.ops.object.camera_add(location=(0, -6, 1.0))
    camera = bpy.context.object
    camera.name = "ReviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.05
    camera.data.lens = 70
    scene.camera = camera
    return camera


def point_camera(camera: bpy.types.Object, location, target=(0, 0, 0.92)) -> None:
    camera.location = location
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


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
        point_camera(camera, location)
        bpy.context.scene.render.filepath = str(RENDER_DIR / f"Honey_BaseBody_v003_{name}.png")
        bpy.ops.render.render(write_still=True)


clear_scene()
human = create_mpfb_human()
camera = setup_scene()
BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
render_views(camera)
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
print(f"Saved MPFB base: {BLEND_PATH}")
print(f"Dimensions: {tuple(round(value, 4) for value in human.dimensions)}")
print(f"Vertices: {len(human.data.vertices)}")
print(f"Rendered review views: {RENDER_DIR}")
