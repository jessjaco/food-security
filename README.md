# AI4FoodSecurity Challenge

This repository holds code for my entries in the [AI4FoodSecurity challenge in
South Africa](https://platform.ai4eo.eu/ai4food-security-south-africa).

## Approach

I took a fairly simple approach to this challenge, since I joined it pretty
late and had limited time to apply solutions. Briefly, I applied a boosted
decision tree methodology to the contest imagery summarized at the
parcel-level. I admit it was a fairly coarse approach, but nevertheless my
submissions ranked well on the leaderboard, though not at the top.

## Data preparation

I first utilized the Sentinel-2 training data, since I am most familiar with
that dataset from previous work, but also eventually incorporated Sentinel-1
and the Planet fusion 5-day interval data. Since I am a little more conversant
with handling geospatial data in R (which arguably also has stronger
capabilities for certain geoprocessing tasks, such as zonal statistics, than
python), I exported the Sentinel data which was supplied in .npy files into
GeoTIFFs. This step also had the added benefit of simplifying more extensive data
exploration (using QGIS). The code for this process is in
[src/process_sentinel.py](src/process_sentinel.py), but the basic framework was
to load relevant data and metadata using `pickle` and `numpy` respectively,
then exporting to GeoTIFF using `rasterio`. (I used a similar process for
Sentinel-1 data).

Once data were in GeoTIFF format, I used R and the
[exactextractr](https://isciences.gitlab.io/exactextractr/) package to extract
summary (zonal) statistics for each parcel in the label datasets. Exactextractr
is a relatively new package and utilizes the exactextract command line tool
written in C++. It has proved more useful than similar functionality in other
packages, mainly due to its speed. For each parcel and image, I calculated the
mean, standard deviation of the mean, and 5 percentile levels (0, 25, 50, 75,
and 100) of the corresponding pixels.

## Model fitting

I used XGBoost via the xgboost R package to create models and predictions. It
was my first experience using the package, but I came to quickly understand
its well-deserved reputation among the machine learning community. It was fast
and did a good job. I spent a fair amount of time on feature engineering and
model parameter tuning, before finding my best solution (a.k.a. running out of
time).

I discovered that many of the Sentinel-2 images, particularly near times
of the growing season were heavily obscured by clouds. Much of the footprint of
the test set was also absent in many images. At first I simply removed
cloud pixels from the images before extracting summary data, but I found that
in many cases the pixels remaining were of low quality and often had extreme
values. As a result, I selected the Sentinel-2 images to use by hand in QGIS,
and limited modeling to only those dates.

To improve the set of available data, particularly in mid-growing season, I
added Sentinel-1 data to the training set. Due to its radar-based nature, it
had great ability to see through clouds and also pick out ground-level
textural-type information. As the [introductory
notebook](https://github.com/AI4EO/tum-planet-radearth-ai4food-challenge/blob/main/notebook/starter-pack.ipynb)
suggested, I calculated the dual-polarized radiometric vegetation index. At
this point I also added a number of vegetation indices based on the Sentinel-2
data, including NDVI, NDWI, NDYI, and PSRI (for NDVI and NDWI, I calculated
using both B08 and B08a as the "red" bands). I also downloaded an incorporated 5-day interval 4-band Planet Fusion Imagery and calculated NDVI.


## Other Approaches

On the last day, I tried a simple multi-layer perceptron approach using the
same summary data. It performed similarly on the training data, though the
model did not seem to generalize as well (i.e. my submissions scored more
poorly). Given time to tune the model, it may have produced a better result.

I performed a decent amount of summary-level data exploration, particularly
related incorporating the time series nature of the data. For instance, here is
a plot of NDVI over the growing season summarized across all parcels in the
corresponding crop types. As you can see there are some pretty start
differences among some crops, while others (for instance, barley and wheat) are
practically indistinguishable. When looking at other bands, I did find
phenological differences (for instance, barley values peaked in S2 B01 before
wheat values), but I was unable to exploit such patterns in modeling.
Ultimately, though I reached nearly 80% accuracy on test submissions, I believe
any further improvement in prediction would require another way to incorporate
the data themselves, not just tweak the models and data I used.
