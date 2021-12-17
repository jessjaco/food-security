from pathlib import Path


planet_paths = Path(
    "data/ref_fusion_competition_south_africa_train_source_planet_5day"
).rglob("*.tif")

print(list(planet_paths))
