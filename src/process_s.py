import argparse
import json
import os
import pickle
from typing import List

import numpy as np
import rasterio as rio
from rasterio.merge import merge


def load_file(path: str):
    if path.endswith("pkl"):
        with open(path, "rb") as f:
            return pickle.load(f)

    with open(path) as j:
        return json.load(j)


def load_npy_file(dirname: str, which_one: str) -> np.ndarray:
    return np.moveaxis(
        np.load(
            os.path.join(dirname, f"{which_one}.npy"),
            mmap_mode="r",
        ),
        -1,
        1,
    )


def get_band_descriptions(stac: dict, type: str = "s2") -> List:
    if type == "s2":
        return [name["name"] for name in stac["properties"]["eo:bands"]] + [
            "is_data",
            "scl",
            "clp",
        ]
    else:
        return ["angle", "mask", "vh", "vv"]


def get_bands(directory: str, time: int, type: str = "s2") -> np.ndarray:
    bands = (
        ["bands", "is_data", "scl", "clp"]
        if type == "s2"
        else ["angle", "mask", "vh", "vv"]
    )
    bands = np.concatenate(
        [load_npy_file(directory, b)[time, :, :, :] for b in bands], axis=0
    )

    if type == "s1":
        bands[2:4, :, :] *= 10000

    return bands


def process(directory: str, suffix: str, type: str = "s2") -> None:
    bbox = load_file(os.path.join(directory, "bbox.pkl"))
    timestamp = load_file(os.path.join(directory, "timestamp.pkl"))
    stac = load_file(os.path.join(directory, "stac.json"))
    band_descriptions = get_band_descriptions(stac, type)

    kwargs = dict(
        driver="GTiff",
        crs="EPSG:" + str(bbox.crs.epsg),
        dtype="uint16",
        nodata=0,
        blockxsize=256,
        blockysize=256,
        compress="LZW",
        tiled="YES",
        predictor="2",
        interleave="band",
    )

    for time in range(len(timestamp)):
        bands = get_bands(directory, time, type)
        n_bands, height, width = bands.shape
        transform = rio.transform.from_bounds(
            bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y, width, height
        )

        output_file = (
            f"data/{type}_tiffs/{type}_{timestamp[time].strftime('%j')}_{suffix}.tif"
        )
        print(output_file)
        if not os.path.exists(output_file):
            with rio.open(
                output_file,
                "w",
                count=n_bands,
                height=height,
                width=width,
                transform=transform,
                **kwargs,
            ) as dst:
                dst.descriptions = band_descriptions
                dst.write(bands)


def mosaic(timestamps, type: str = "s2") -> None:
    for timestamp in timestamps:
        key = f"data/{type}_tiffs/{type}_{timestamp.strftime('%j')}"
        files = [
            os.path.join(os.path.dirname(key), f)
            for f in os.listdir(os.path.dirname(key))
            if f.startswith(os.path.basename(key)) and f.endswith(".tif")
        ]
        print(files)
        mosaic, transformation = merge(files)
        with rio.open(files[0], "r") as src:
            kwargs = src.meta.copy()
            band_descriptions = src.descriptions

        kwargs.update(
            {
                "height": mosaic.shape[1],
                "width": mosaic.shape[2],
                "transform": transformation,
                "blockxsize": 256,
                "blockysize": 256,
                "compress": "LZW",
                "tiled": "YES",
                "predictor": "2",
                "interleave": "band",
            }
        )

        output_file = key + ".tif"
        print(output_file)
        with rio.open(output_file, "w", **kwargs) as dest:
            dest.descriptions = band_descriptions
            dest.write(mosaic)

        [os.remove(file) for file in files]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-t", "--type", default="s2")
    args = parser.parse_args()
    if args.type == "s2":
        process(
            "data/input/ref_fusion_competition_south_africa_test_source_sentinel_2/ref_fusion_competition_south_africa_test_source_sentinel_2_34S_20E_259N_2017/",
            "20",
        )
        process(
            "data/input/ref_fusion_competition_south_africa_train_source_sentinel_2/ref_fusion_competition_south_africa_train_source_sentinel_2_34S_19E_258N_34S_19E_258N_2017/",
            "8",
        )
        process(
            "data/input/ref_fusion_competition_south_africa_train_source_sentinel_2/ref_fusion_competition_south_africa_train_source_sentinel_2_34S_19E_259N_34S_19E_259N_2017/",
            "9",
        )

        some_directory = "data/input/ref_fusion_competition_south_africa_test_source_sentinel_2/ref_fusion_competition_south_africa_test_source_sentinel_2_34S_20E_259N_2017"
        timestamps = load_file(os.path.join(some_directory, "timestamp.pkl"))
        mosaic(timestamps)
    else:
        process(
            "data/input/ref_fusion_competition_south_africa_test_source_sentinel_1/ref_fusion_competition_south_africa_test_source_sentinel_1_asc_34S_20E_259N_2017/",
            "20",
            "s1",
        )
        process(
            "data/input/ref_fusion_competition_south_africa_train_source_sentinel_1/ref_fusion_competition_south_africa_train_source_sentinel_1_34S_19E_258N_asc_34S_19E_258N_2017/",
            "8",
            "s1",
        )
        process(
            "data/input/ref_fusion_competition_south_africa_train_source_sentinel_1/ref_fusion_competition_south_africa_train_source_sentinel_1_34S_19E_259N_asc_34S_19E_259N_2017/",
            "9",
            "s1",
        )
        some_directory = "data/input/ref_fusion_competition_south_africa_train_source_sentinel_1/ref_fusion_competition_south_africa_train_source_sentinel_1_34S_19E_259N_asc_34S_19E_259N_2017/"
        timestamps = load_file(os.path.join(some_directory, "timestamp.pkl"))
        mosaic(timestamps, "s1")
