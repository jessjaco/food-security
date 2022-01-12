## AI4FoodSecurity Challenge

This repository holds code for my entries in the [AI4FoodSecurity challenge in
South Africa](https://platform.ai4eo.eu/ai4food-security-south-africa).

### Approach

I took a fairly simple approach to this challenge, since I joined it pretty
late and had limited time to apply solutions. Briefly, I applied a boosted
decision tree methodology to the contest imagery summarized at the
parcel-level. I admit it was a fairly coarse approach, but nevertheless my
submissions ranked well on the leaderboard, though not at the top.

#### Data preparation

I first utilized the Sentinel-2 training data, since I am most familiar with
that dataset from previous work, but also eventually incorporated Sentinel-1
and the Planet fusion 5-day interval data. Since I am a little more conversant
with handling geospatial data in R (which arguably also has much stronger
capabilities for certain geoprocessing tasks, such as zonal statistics, than
python), I exported the Sentinel data which was supplied in .npy files into
GeoTIFFs. This step also had the added benefit of simplify more extensive data
exploration (using QGIS). The code for this process is in
[src/process_sentinel.py](src/process_sentinel.py), but the basic framework was
to load relevant data and metadata using `pickle` and `numpy` respectively,
then exporting to GeoTIFF using `rasterio`. (I used a similar process for
Sentinel-1 data).


Once data were in GeoTIFF format, I used R and the
[exactextractr](https://isciences.gitlab.io/exactextractr/) package to extract summary (zonal) statistics for each parcel in the label
datasets. Exactextractr is a relatively new package and utilizes the command
line
