from os.path import join
import json
import pickle

import numpy as np
import rasterio as rio


def get_dirname(eight_or_nine: str) -> str:
    return "data/input/ref_fusion_competition_south_africa_train_source_sentinel_2/ref_fusion_competition_south_africa_train_source_sentinel_2_34S_19E_25{eight_or_nine}N_34S_19E_25{eight_or_nine}N_2017/".format(
        eight_or_nine=eight_or_nine
    )


def load_npy_file(dirname: str, which_one: str) -> np.ndarray:
    return np.moveaxis(
        np.load(
            join(dirname, f"{which_one}.npy"),
            mmap_mode="r",
        ),
        -1,
        1,
    )


def load_npy_files(which_one: str = "bands", time: int = 0) -> np.ndarray:
    data_8 = load_npy_file(get_dirname("8"), which_one)
    data_9 = load_npy_file(get_dirname("9"), which_one)
    dir_19 = "data/input/ref_fusion_competition_south_africa_test_source_sentinel_2/ref_fusion_competition_south_africa_test_source_sentinel_2_34S_20E_259N_2017/"
    data_19 = load_npy_file(dir_19, which_one)

    return np.concatenate((data_9[time, :, :, :], data_8[time, :, :, :]), axis=1)


with open(join(get_dirname("8"), "bbox.pkl"), "rb") as f:
    bbox8 = pickle.load(f)

with open(join(get_dirname("9"), "bbox.pkl"), "rb") as f:
    bbox9 = pickle.load(f)

with open(join(get_dirname("8"), "timestamp.pkl"), "rb") as f:
    timestamp = pickle.load(f)

with open(join(get_dirname("8"), "stac.json")) as j:
    stac = json.load(j)

band_descriptions = [name["common_name"] for name in stac["properties"]["eo:bands"]] + [
    "is_data",
    "scl",
    "clp",
]


kwargs = dict(
    driver="GTiff",
    crs="EPSG:" + str(bbox8.crs.epsg),
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
    bands = load_npy_files("bands", time)
    is_data = load_npy_files("is_data", time)
    scl = load_npy_files("scl", time)
    clp = load_npy_files("clp", time)
    all_bands = np.concatenate((bands, is_data, scl, clp), axis=0)
    n_bands, height, width = all_bands.shape
    transform = rio.transform.from_bounds(
        bbox8.min_x, bbox8.min_y, bbox8.max_x, bbox9.max_y, width, height
    )

    output_file = f"data/s2_{timestamp[time].strftime('%j')}.tif"
    print(output_file)
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
        dst.write(all_bands)
