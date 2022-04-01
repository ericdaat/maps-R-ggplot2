# Draw beautiful maps with R and ggplot2 library

In this repository we are going to learn how to draw maps using the R
programming language and ggplot2 library. While I am mostly using
Python for everything else, I must admit R produces beautiful figures and I have been using it extensively for data visualization, especially for drawing maps.

- Download the [polygon file](https://data.beta.nyc/dataset/nyc-zip-code-tabulation-areas/resource/894e9162-871c-4552-a09c-c6915d8783fb?view_id=2c40fce3-0bb2-46d3-bb67-04a935151a96).
- Download the [restaurants dataset](https://data.cityofnewyork.us/Health/DOHMH-New-York-City-Restaurant-Inspection-Results/43nn-pn8j).

## Installation

Here are the librairies we are going to need for this project:

- [geojsonio](https://cran.r-project.org/web/packages/geojsonio/index.html)
- [broom](https://cran.r-project.org/web/packages/broom/vignettes/broom.html)
- [sf](https://cran.r-project.org/web/packages/sf/index.html)
- [osmdata](https://cran.r-project.org/web/packages/osmdata/vignettes/osmdata.html)
- [ggplot2](https://cran.r-project.org/web/packages/ggplot2/index.html)
- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)
- [ggnewscale](https://cran.r-project.org/web/packages/ggnewscale/index.html)

## Load the datasets in R

The two datasets we downloaded earlier should be named
`zip_code_040114.geojson`
and `DOHMH_New_York_City_Restaurant_Inspection_Results.csv`. I stored them
into a folder named `data`, and the following code will read these two
files in R.

We first read the geojson file, then convert it to a spatial data frame
indexed with zip code, so that we can display the counties shapes on a map.
We then load the restaurants, and keep only the first 100 entries for
clarity.

``` R
# NYC Geometry
spdf_file <- geojson_read(  # Read the geojson file
  "data/zip_code_040114.geojson",
  what = "sp"
)
stats_df <- as.data.frame(spdf_file)  # Export the census statistics in another data frame variable
spdf_file <- tidy(  # Convert it to a spatial data frame, with zip code as index
  spdf_file,
  region="ZIPCODE"  # Use ZIPCODE variable as index, the index will be named "id"
)

# Restaurants data
restaurants <- read.csv(  # Read the csv file as a data frame
    "data/DOHMH_New_York_City_Restaurant_Inspection_Results.csv"
)
restaurants <- restaurants %>% head(100)  # Keep only the first 100 restaurants
restaurants <- restaurants %>%  # Replace missing inspection grades with NA
  mutate(GRADE=replace(GRADE, GRADE == "", NA))
```

## Drawing maps

There are different kind of maps you can draw, like
[Choropleth](https://r-graph-gallery.com/choropleth-map.html),
[Connection](https://r-graph-gallery.com/connection-map.html)
or [Bubble](https://r-graph-gallery.com/bubble-map.html) maps. In the
following sections, we are going to give various maps examples
based on the NYC datasets we downloaded. The code is provided and
explained.

The code is mostly similar for every map, and arranged in the following
manner:

``` R
ggplot() +  # ggplot init
  # 1. adding layers from here
  geom_polygon(data=...,        # layer data
               aes(x=long,      # longitude on x axis
                   y=lat,       # latitude on y axis
                   group=group, # polygons from the same county share the same group
                   fill=...),   # fill polygons with some variable
               color="black",   # polygons borders are colored in black
               size=.2) +       # polygons borders are .2 width
  # 2. plot settings from here
  theme_void() +                # remove all axes
  coord_map() +                 # change coordinate system to map
  scale_fill_distiller(...) +   # customize the color palette for fill
  labs(title=...,               # add titles and legends
       subtitle=...,
       fill=...)
```
