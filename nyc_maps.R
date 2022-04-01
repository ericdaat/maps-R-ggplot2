library(geojsonio)
library(broom)
library(ggplot2)
library(dplyr)
library(ggnewscale)
library(sf)
library(osmdata)


#############
# Load data #
#############

# NY Geometry
spdf_file <- geojson_read(
  "data/zip_code_040114.geojson",
  what = "sp"
)
stats_df <- as.data.frame(spdf_file)
spdf_file <- tidy(
  spdf_file,
  region="ZIPCODE"
)

# Restaurants data
# https://data.cityofnewyork.us/Health/DOHMH-New-York-City-Restaurant-Inspection-Results/43nn-pn8j
restaurants <- read.csv("data/DOHMH_New_York_City_Restaurant_Inspection_Results.csv")
restaurants <- restaurants %>% head(100)
restaurants <- restaurants %>% 
  mutate(GRADE=replace(GRADE, GRADE == "", NA))


########
# Maps #
########

# Population
map_1 <- ggplot() +
  geom_polygon(data=spdf_file %>%
                 inner_join(stats_df, c("id"="ZIPCODE")),
               aes(x=long,
                   y=lat,
                   group=group,
                   fill=POPULATION),
               color="white",
               size=.2) +
  theme_void() +
  coord_map() +
  scale_fill_distiller(palette = "YlGnBu", direction = 1) +
  labs(title="Population in New York City",
       subtitle="Neighborhoods are filled by population",
       fill="Population")

ggsave(
  map_1, 
  filename="map_1.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)

# Pop density binned
map_1_binned <- ggplot() +
  geom_polygon(data=spdf_file %>% 
                 inner_join(stats_df, c("id"="ZIPCODE")),
               aes(x=long, 
                   y=lat, 
                   group=group,
                   fill=POPULATION),
               color="white",
               size=.2) +
  theme_void() +
  coord_map() +
  scale_fill_binned(type = "viridis", direction=-1) +
  labs(title="Population in New York City",
       subtitle="Neighborhoods are filled by population",
       fill="Population")

ggsave(
  map_1_binned, 
  filename="map_1_binned.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)

# Restaurants
map_2 <- ggplot() +
  geom_polygon(data=spdf_file,
               aes(x=long, 
                   y=lat, 
                   group=group),
               alpha=0,
               color="black",
               size=.2) +
  geom_point(data=restaurants,
             aes(x=Longitude,
                 y=Latitude),
             fill="red",
             alpha=.6,
             size=3,
             shape=22) +
  theme_void() +
  coord_map() +
  labs(title="Restaurants in New York City")

ggsave(
  map_2, 
  filename="map_2.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)

# Restaurants by score and grade
map_3 <- ggplot() +
  geom_polygon(data=spdf_file,
               aes(x=long, 
                   y=lat, 
                   group=group),
               alpha=0,
               color="black",
               size=.2) +
  geom_point(data=restaurants,
             aes(x=Longitude,
                 y=Latitude,
                 size=SCORE,
                 fill=GRADE),
             alpha=.8,
             shape=22) +
  theme_void() +
  coord_map() +
  scale_size(limits = c(0, 100)) +
  scale_fill_manual(values=c("A"="#2a9d8f",
                             "B"="#e9c46a",
                             "C"="#e76f51",
                             "N"="#8ecae6",
                             "Z"="#219ebc"),
                    na.value="grey") +
  guides(fill=guide_legend(override.aes = list(size = 7))) +
  labs(title="Restaurants in the state of NY",
       subtitle="Sized by score, colored by grade",
       size="Score",
       fill="Grade")

ggsave(
  map_3, 
  filename="map_3.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)

# Restaurants by score and grade, with population density
map_4 <- ggplot() +
  geom_polygon(data=spdf_file %>% 
                 inner_join(stats_df, c("id"="ZIPCODE")),
               aes(x=long, 
                   y=lat, 
                   group=group,
                   fill=POPULATION),
               color="white",
               size=.2) +
  scale_fill_distiller(palette = "YlGnBu", direction = 1) +
  labs(fill="Population") +
  new_scale("fill") +
  geom_point(data=restaurants,
             aes(x=Longitude,
                 y=Latitude,
                 size=SCORE,
                 fill=GRADE),
             alpha=.8,
             shape=22) +
  theme_void() +
  coord_map() +
  scale_size(limits = c(0, 100)) +
  scale_fill_manual(values=c("A"="#2a9d8f",
                             "B"="#e9c46a",
                             "C"="#e76f51",
                             "N"="#8ecae6",
                             "Z"="#219ebc"),
                    na.value="grey") +
  guides(fill=guide_legend(override.aes = list(size = 7))) +
  labs(title="Restaurants in New York City",
       subtitle="Sized by score, colored by grade. With population.",
       size="Score",
       fill="Grade")

ggsave(
  map_4, 
  filename="map_4.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)

###################################
# Transit data from OpenStreeMaps #
###################################

compute_bbox <- function(restaurants, buffer=.3) {
  restaurants_sf <- st_as_sf(restaurants,
                            coords=c("Longitude", "Latitude"),
                            crs=4326)
  restaurants_sf <- st_transform(restaurants_sf)
  bbox <- st_bbox(st_buffer(restaurants_sf, buffer))
  
  return(bbox)
}

bbox <- compute_bbox(restaurants)

osm_railway_for_bbox <- function(bbox, timeout=60) {
  q <- opq(bbox=bbox, timeout=timeout)
  
  q1 <- add_osm_feature(q, key = "railway", value = "subway")
  # q2 <- add_osm_feature(q, key = "railway", value = "rail")
  
  subway <- osmdata_sf(q1)$osm_lines
  # rail <- osmdata_sf(q2)$osm_lines
  
  rails <- c(
    st_geometry(subway)
    # st_geometry(rail)
  )
  
  return(rails)
}

nyc_railway <- osm_railway_for_bbox(bbox)

map_5 <- ggplot() +
  geom_polygon(data=spdf_file,
               aes(x=long, 
                   y=lat, 
                   group=group),
               alpha=0,
               color="black",
               size=.2) +
  geom_sf(data=nyc_railway,
          size=.3,
          alpha=1,
          color="red") +
  theme_void() +
  coord_sf() +
  labs(title="Railway from OpenStreetMaps",
       subtitle="Showing subway and rail")


ggsave(
  map_5, 
  filename="map_5.png",
  path = "~/Code/ericdaat.github.io/assets/img/articles/maps-ggplot2", 
  width = 15,
  height = 10
)
