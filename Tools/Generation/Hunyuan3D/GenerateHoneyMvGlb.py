from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
import time
from pathlib import Path
from typing import Dict, Iterable, List, Tuple, Union


INSTALL_HELP = """
Missing Python dependencies for Hunyuan3D.

Suggested setup:
  git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git
  cd Hunyuan3D-2
  python -m venv .venv
  .\\.venv\\Scripts\\Activate.ps1

  # Install PyTorch from https://pytorch.org/get-started/locally/
  # Example for CUDA 12.1:
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

  pip install -r requirements.txt
  pip install -e .

  # Needed for textured GLB export.
  python .\\hy3dgen\\texgen\\custom_rasterizer\\setup.py install
  python .\\hy3dgen\\texgen\\differentiable_renderer\\setup.py install
"""


LOCAL_CACHE_ROOT = Path(__file__).resolve().parent / "cache"
os.environ.setdefault("HF_HOME", str(LOCAL_CACHE_ROOT / "huggingface"))
os.environ.setdefault("U2NET_HOME", str(LOCAL_CACHE_ROOT / "u2net"))
(LOCAL_CACHE_ROOT / "huggingface").mkdir(parents=True, exist_ok=True)
(LOCAL_CACHE_ROOT / "u2net").mkdir(parents=True, exist_ok=True)


try:
    import torch
except ImportError as exc:
    raise SystemExit(f"{exc}\n{INSTALL_HELP}") from exc

try:
    from PIL import Image, ImageDraw, ImageOps
except ImportError as exc:
    raise SystemExit(f"{exc}\n{INSTALL_HELP}") from exc


_BACKGROUND_REMOVER = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Honey GLB from front/side/back turnaround images with Hunyuan3D-2mv.",
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=Path("Reference/Captures/Honey/TurnaroundSplit"),
        help="Directory containing front.png, side.png, and back.png.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("Assets/Generated/Hunyuan3D/Honey"),
        help="Directory for generated GLB and preprocessed views.",
    )
    parser.add_argument("--front-name", default="front.png")
    parser.add_argument("--side-name", default="side.png")
    parser.add_argument("--back-name", default="back.png")
    parser.add_argument(
        "--side-source",
        choices=("left", "right"),
        default="right",
        help="Set to right if side.png is a right-side view and must be mirrored to Hunyuan's left view.",
    )
    parser.add_argument(
        "--background-mode",
        choices=("auto", "hunyuan", "floodfill", "none"),
        default="auto",
        help="Background removal strategy before view alignment.",
    )
    parser.add_argument(
        "--floodfill-threshold",
        type=int,
        default=64,
        help="Color tolerance for fallback border flood-fill background removal.",
    )
    parser.add_argument(
        "--canvas-size",
        type=int,
        default=1024,
        help="Output square canvas size for each normalized view.",
    )
    parser.add_argument(
        "--subject-height-ratio",
        type=float,
        default=0.90,
        help="Target subject height ratio in the normalized square canvas.",
    )
    parser.add_argument(
        "--floor-y-ratio",
        type=float,
        default=0.96,
        help="Where to place the bottom of the subject on the normalized square canvas.",
    )
    parser.add_argument("--shape-model", default="tencent/Hunyuan3D-2mv")
    parser.add_argument("--shape-subfolder", default="hunyuan3d-dit-v2-mv")
    parser.add_argument("--shape-variant", default="fp16")
    parser.add_argument("--texture-model", default="tencent/Hunyuan3D-2")
    parser.add_argument(
        "--texture-input-mode",
        choices=("front", "front-left-back"),
        default="front-left-back",
        help="Reference images passed to Hunyuan3D-Paint after shape generation.",
    )
    parser.add_argument("--device", default="cuda")
    parser.add_argument("--num-inference-steps", type=int, default=50)
    parser.add_argument("--octree-resolution", type=int, default=380)
    parser.add_argument("--num-chunks", type=int, default=20000)
    parser.add_argument("--seed", type=int, default=12345)
    parser.add_argument(
        "--skip-texture",
        action="store_true",
        help="Export only the white mesh GLB and skip texture generation.",
    )
    parser.add_argument(
        "--reuse-white-glb",
        action="store_true",
        help="If Honey_white_mv.glb already exists in output-dir, reuse it instead of regenerating shape.",
    )
    parser.add_argument(
        "--no-component-cleanup",
        action="store_true",
        help="Keep all disconnected mesh components instead of exporting only the main body component.",
    )
    parser.add_argument(
        "--prepare-only",
        action="store_true",
        help="Only write normalized front/left/back PNG previews, do not run model inference.",
    )
    return parser.parse_args()


def resolve_existing_path(path_value: Path) -> Path:
    path = path_value if path_value.is_absolute() else (Path.cwd() / path_value)
    if not path.exists():
        raise FileNotFoundError(f"Path not found: {path}")
    return path.resolve()


def resolve_output_dir(path_value: Path) -> Path:
    path = path_value if path_value.is_absolute() else (Path.cwd() / path_value)
    path.mkdir(parents=True, exist_ok=True)
    return path.resolve()


def image_has_alpha_cutout(image: Image.Image) -> bool:
    if image.mode != "RGBA":
        return False
    alpha_min, _alpha_max = image.getchannel("A").getextrema()
    return alpha_min < 255


def estimate_border_rgb(image: Image.Image, sample_size: int = 16) -> Tuple[int, int, int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    patch = max(1, min(sample_size, width, height))

    samples = []
    boxes = (
        (0, 0, patch, patch),
        (width - patch, 0, width, patch),
        (0, height - patch, patch, height),
        (width - patch, height - patch, width, height),
    )
    for box in boxes:
        samples.extend(pixel[:3] for pixel in rgba.crop(box).getdata())

    return tuple(int(round(statistics.median(channel))) for channel in zip(*samples))


def border_seed_points(width: int, height: int) -> Iterable[Tuple[int, int]]:
    for x in range(width):
        yield (x, 0)
        if height > 1:
            yield (x, height - 1)
    for y in range(1, max(1, height - 1)):
        yield (0, y)
        if width > 1:
            yield (width - 1, y)


def remove_background_with_floodfill(image: Image.Image, threshold: int) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    background_rgb = estimate_border_rgb(rgba)
    fill_color = (background_rgb[0], background_rgb[1], background_rgb[2], 0)

    for seed in border_seed_points(width, height):
        pixel = rgba.getpixel(seed)
        if pixel[3] == 0:
            continue
        if max(abs(int(pixel[channel]) - background_rgb[channel]) for channel in range(3)) > threshold:
            continue
        ImageDraw.floodfill(rgba, seed, fill_color, thresh=threshold)

    return remove_horizontal_guide_artifacts(rgba)


def remove_horizontal_guide_artifacts(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    min_run_length = max(64, width // 10)

    for y in range(height):
        run_start = None
        for x in range(width + 1):
            is_guide_pixel = False
            if x < width:
                r, g, b, a = pixels[x, y]
                channel_delta = max(r, g, b) - min(r, g, b)
                if a > 0 and min(r, g, b) >= 80 and channel_delta <= 24:
                    is_guide_pixel = True

            if is_guide_pixel:
                if run_start is None:
                    run_start = x
            elif run_start is not None:
                if (x - run_start) >= min_run_length:
                    for clear_x in range(run_start, x):
                        r, g, b, _a = pixels[clear_x, y]
                        pixels[clear_x, y] = (r, g, b, 0)
                run_start = None

    return rgba


def remove_background(image: Image.Image, mode: str, floodfill_threshold: int) -> Image.Image:
    if image_has_alpha_cutout(image):
        return image.convert("RGBA")
    if mode == "none":
        return image.convert("RGBA")
    if mode in ("auto", "hunyuan"):
        try:
            return remove_background_with_hunyuan(image)
        except Exception as exc:
            if mode == "hunyuan":
                raise
            print(
                f"[warn] Hunyuan/rembg background removal failed, fallback to floodfill: {exc}",
                file=sys.stderr,
            )
    return remove_background_with_floodfill(image, floodfill_threshold)


def remove_background_with_hunyuan(image: Image.Image) -> Image.Image:
    global _BACKGROUND_REMOVER
    if _BACKGROUND_REMOVER is None:
        from hy3dgen.rembg import BackgroundRemover

        _BACKGROUND_REMOVER = BackgroundRemover()
    return _BACKGROUND_REMOVER(image.convert("RGB")).convert("RGBA")


def fit_subject_to_square_canvas(
    image: Image.Image,
    canvas_size: int,
    subject_height_ratio: float,
    floor_y_ratio: float,
) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Foreground alpha bbox is empty after background removal.")

    subject = rgba.crop(bbox)
    target_height = max(1, int(round(canvas_size * subject_height_ratio)))
    scale = min(
        target_height / subject.height,
        canvas_size / subject.width,
    )
    resized_size = (
        max(1, int(round(subject.width * scale))),
        max(1, int(round(subject.height * scale))),
    )
    subject = subject.resize(resized_size, resample=Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = max(0, (canvas_size - subject.width) // 2)
    floor_y = int(round(canvas_size * floor_y_ratio))
    y = max(0, min(canvas_size - subject.height, floor_y - subject.height))
    canvas.alpha_composite(subject, dest=(x, y))
    return canvas


def load_normalized_views(args: argparse.Namespace) -> Dict[str, Image.Image]:
    input_dir = resolve_existing_path(args.input_dir)
    source_files = {
        "front": input_dir / args.front_name,
        "left": input_dir / args.side_name,
        "back": input_dir / args.back_name,
    }

    views: Dict[str, Image.Image] = {}
    for view_name, source_path in source_files.items():
        if not source_path.is_file():
            raise FileNotFoundError(f"Missing {view_name} source image: {source_path}")

        image = Image.open(source_path).convert("RGBA")
        if view_name == "left" and args.side_source == "right":
            image = ImageOps.mirror(image)

        image = remove_background(
            image=image,
            mode=args.background_mode,
            floodfill_threshold=args.floodfill_threshold,
        )
        views[view_name] = fit_subject_to_square_canvas(
            image=image,
            canvas_size=args.canvas_size,
            subject_height_ratio=args.subject_height_ratio,
            floor_y_ratio=args.floor_y_ratio,
        )

    return views


def save_preprocessed_views(views: Dict[str, Image.Image], output_dir: Path) -> Path:
    preview_dir = output_dir / "preprocessed_views"
    preview_dir.mkdir(parents=True, exist_ok=True)

    for name, image in views.items():
        image.save(preview_dir / f"{name}.png")

    canvas_size = next(iter(views.values())).size[0]
    contact_sheet = Image.new("RGBA", (canvas_size * 3, canvas_size), (32, 32, 32, 255))
    for index, name in enumerate(("front", "left", "back")):
        tile = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 255))
        tile.alpha_composite(views[name])
        contact_sheet.paste(tile, (index * canvas_size, 0))
    contact_sheet.save(preview_dir / "_contact_sheet.png")
    return preview_dir


def build_shape_pipeline(args: argparse.Namespace):
    from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline

    kwargs = {
        "subfolder": args.shape_subfolder,
        "device": args.device,
    }
    if args.shape_variant:
        kwargs["variant"] = args.shape_variant

    return Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(args.shape_model, **kwargs)


def build_texture_pipeline(args: argparse.Namespace):
    from hy3dgen.texgen import Hunyuan3DPaintPipeline

    try:
        return Hunyuan3DPaintPipeline.from_pretrained(args.texture_model, device=args.device)
    except TypeError:
        return Hunyuan3DPaintPipeline.from_pretrained(args.texture_model)


def select_texture_input(
    args: argparse.Namespace,
    views: Dict[str, Image.Image],
) -> Union[Image.Image, List[Image.Image]]:
    if args.texture_input_mode == "front":
        return views["front"]
    if args.texture_input_mode == "front-left-back":
        return [views["front"], views["left"], views["back"]]
    raise ValueError(f"Unsupported texture input mode: {args.texture_input_mode}")


def keep_main_mesh_component(mesh):
    parts = mesh.split(only_watertight=False)
    if len(parts) <= 1:
        return mesh, []

    def score_component(part):
        extents = part.extents
        return (
            float(extents[0] * extents[1] * extents[2]),
            len(part.faces),
            len(part.vertices),
        )

    main_part = max(parts, key=score_component)
    removed_parts = []
    for part in parts:
        if part is main_part:
            continue
        removed_parts.append(
            {
                "faces": len(part.faces),
                "vertices": len(part.vertices),
                "center": part.bounds.mean(axis=0).tolist(),
                "extents": part.extents.tolist(),
            }
        )
    return main_part, removed_parts


def export_meshes(args: argparse.Namespace, views: Dict[str, Image.Image], output_dir: Path) -> Dict[str, str]:
    if args.device.startswith("cuda") and not torch.cuda.is_available():
        raise RuntimeError("CUDA is not available. Use --device cpu or install a CUDA-enabled PyTorch build.")

    white_glb_path = output_dir / "Honey_white_mv.glb"
    textured_glb_path = output_dir / "Honey_textured_mv.glb"

    if args.reuse_white_glb and white_glb_path.is_file():
        import trimesh

        mesh = trimesh.load(white_glb_path, force="mesh")
        result = {
            "white_glb": str(white_glb_path),
            "shape_elapsed_seconds": "reused",
        }
    else:
        shape_pipeline = build_shape_pipeline(args)
        generator = torch.manual_seed(args.seed)

        started_at = time.time()
        mesh = shape_pipeline(
            image=views,
            num_inference_steps=args.num_inference_steps,
            octree_resolution=args.octree_resolution,
            num_chunks=args.num_chunks,
            generator=generator,
            output_type="trimesh",
        )[0]
        elapsed_seconds = time.time() - started_at

        mesh.export(white_glb_path)
        result = {
            "white_glb": str(white_glb_path),
            "shape_elapsed_seconds": f"{elapsed_seconds:.2f}",
        }

    if not args.no_component_cleanup:
        mesh, removed_parts = keep_main_mesh_component(mesh)
        if removed_parts:
            mesh.export(white_glb_path)
            result["removed_components"] = removed_parts

    if args.skip_texture:
        return result

    texture_pipeline = build_texture_pipeline(args)
    texture_input = select_texture_input(args, views)
    mesh = texture_pipeline(mesh, image=texture_input)
    mesh.export(textured_glb_path)
    result["textured_glb"] = str(textured_glb_path)
    result["texture_input_mode"] = args.texture_input_mode
    return result


def write_manifest(args: argparse.Namespace, output_dir: Path, preview_dir: Path, result: Dict[str, str]) -> Path:
    manifest_path = output_dir / "Honey_mv_generation_manifest.json"
    payload = {
        "input_dir": str(resolve_existing_path(args.input_dir)),
        "output_dir": str(output_dir),
        "preview_dir": str(preview_dir),
        "side_source": args.side_source,
        "background_mode": args.background_mode,
        "canvas_size": args.canvas_size,
        "subject_height_ratio": args.subject_height_ratio,
        "floor_y_ratio": args.floor_y_ratio,
        "shape_model": args.shape_model,
        "shape_subfolder": args.shape_subfolder,
        "shape_variant": args.shape_variant,
        "texture_model": args.texture_model,
        "texture_input_mode": args.texture_input_mode,
        "device": args.device,
        "num_inference_steps": args.num_inference_steps,
        "octree_resolution": args.octree_resolution,
        "num_chunks": args.num_chunks,
        "seed": args.seed,
        "skip_texture": args.skip_texture,
        "reuse_white_glb": args.reuse_white_glb,
        "no_component_cleanup": args.no_component_cleanup,
        "prepare_only": args.prepare_only,
        "result": result,
    }
    manifest_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return manifest_path


def main() -> int:
    args = parse_args()
    output_dir = resolve_output_dir(args.output_dir)

    views = load_normalized_views(args)
    preview_dir = save_preprocessed_views(views, output_dir)
    print(f"Preprocessed views saved to: {preview_dir}")

    result: Dict[str, str] = {}
    if not args.prepare_only:
        result = export_meshes(args, views, output_dir)
        for key, value in result.items():
            print(f"{key}: {value}")

    manifest_path = write_manifest(args, output_dir, preview_dir, result)
    print(f"Manifest saved to: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
