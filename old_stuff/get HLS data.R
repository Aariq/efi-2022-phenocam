site_data <- 
  readr::read_csv(
    "https://raw.githubusercontent.com/eco4cast/neon4cast-phenology/master/Phenology_NEON_Field_Site_Metadata_20210928.csv"
  )

# reference https://git.earthdata.nasa.gov/projects/LPDUR/repos/hls_tutorial_r/browse/Scripts/HLS_Tutorial.Rmd

library(raster)
library(tidyverse)
library(jsonlite)
library(httr)
library(curl)
library(foreach)
library(doSNOW)

cl <- makeCluster(20, outfile = "")
registerDoSNOW(cl)
# source("./earthdata_netrc_setup.R")

outDir<-"./data/HLS"
dir.create(outDir, recursive = T)
search_URL <- 'https://cmr.earthdata.nasa.gov/stac/LPCLOUD/search'
HLS_col <- list("HLSL30.v2.0")



hls_df_allsite<-vector(mode="list")
for (s in 1:nrow(site_data)) {
  sitename<-site_data$field_site_id[s]
  lat<- site_data$field_latitude[s]
  lon<- site_data$field_longitude[s]
  site_sp<-SpatialPoints(cbind(lon, lat), proj4string = CRS("+proj=longlat +datum=WGS84"))
  site_ext<-extent(site_sp)
  bbox <- paste(site_ext[1], site_ext[3], site_ext[2], site_ext[4], sep = ',')
  
  for (year in 2015:2021) {
    datetime <- paste0(year,"-01-01T00:00:00Z/",year,"-12-31T23:59:59Z")   # YYYY-MM-DDTHH:MM:SSZ/YYYY-MM-DDTHH:MM:SSZ
    
    search_body <- list(limit=100,
                        datetime=datetime,
                        bbox= bbox,
                        collections= HLS_col)
    
    search_req <- httr::POST(search_URL, body = search_body, encode = "json") %>% 
      httr::content(as = "text") %>% 
      fromJSON()
    cat('There are',search_req$numberMatched, 'features matched our request.')
    
    search_features <- search_req$features
    
    # browse_image_url <- Feature1$assets$browse$href
    # browse_req <- GET(browse_image_url) %>% 
    #   httr::content()  
    # 
    # plot(0:1, 0:1, type = "n",ann=FALSE,axes=FALSE)
    # rasterImage(browse_req,0, 0, 1,1) 
    
    granule_list <- list()
    n <- 1
    for (item in row.names(search_features)){                       # Get the NIR, Red, and Quality band layer names
      if (search_features[item,]$collection == 'HLSL30.v2.0'){
        evi_bands <- c('B02', 'B03','B04','B05','Fmask')
      }
      for(b in evi_bands){
        f <- search_features[item,]
        b_assets <- f$assets[[b]]$href
        
        df <- data.frame(Collection = f$collection,                    # Make a data frame including links and other info
                         Granule_ID = f$id,
                         Cloud_Cover = f$properties$`eo:cloud_cover`,
                         band = b,
                         Asset_Link = b_assets, stringsAsFactors=FALSE)
        granule_list[[n]] <- df
        n <- n + 1
      }
    }
    
    # # Create a searchable datatable
    search_df <- do.call(rbind, granule_list)
    # DT::datatable(search_df)
    
    dir.create(paste0(outDir, "/", sitename))
    foreach (url = search_df$Asset_Link, .packages=c("tidyverse","curl")) %dopar% {
      system(paste0("curl -b ~/.urs_cookies -L -n ",
                    url, " -o ", outDir, "/", sitename, "/", str_split(url, "/", simplify = T)[,7])  )
      url
    }
  }
  
}

# possibly()

for (s in 1:nrow(site_data)) {
  sitename<-site_data$field_site_id[s]
  lat<- site_data$field_latitude[s]
  lon<- site_data$field_longitude[s]
  site_sp<-SpatialPoints(cbind(lon, lat), proj4string = CRS("+proj=longlat +datum=WGS84"))
  
  coordinate_reference <- "+proj=utm +zone=18 +ellps=WGS84 +units=m +no_defs"
  site_sp_utm <- spTransform(site_sp, crs(coordinate_reference)) # Transfer CRS
  
  hls_df_list<-vector(mode="list", length=5)
  for (band in c("Fmask", "blue", "green", "red", "nir")) {
    if (band=="Fmask") {bandname<-"Fmask"}
    if (band=="blue") {bandname<-"B02"}
    if (band=="green") {bandname<-"B03"}
    if (band=="red") {bandname<-"B04"}
    if (band=="nir") {bandname<-"B05"}
    
    files<-list.files(paste0(outDir, "/", sitename), paste0("*",bandname,".tif"), recursive = T, full.names = T)
    time_df<-list.files(paste0(outDir, "/", sitename),  paste0("*",bandname,".tif"), recursive = T) %>% 
      str_split(pattern="\\.", simplify = T) %>% 
      data.frame() %>% 
      dplyr::select(filename=X4) %>% 
      mutate(year=substr(filename,1,4)%>% as.integer(),
             doy=substr(filename,5,7) %>% as.integer()) %>% 
      mutate(date=as.Date(doy, origin = paste0(year,"-01-01"))) %>% 
      mutate(f=row_number()) %>% 
      dplyr::select(-filename)
    
    nday<-length(files)
    hls_mat<-foreach (f = 1:nday,
                      .packages = c("raster"),
                      .combine="rbind") %dopar%{
                        
                        tryCatch({
                          file<-files[f]
                          hls_ras<-raster(file)
                          
                          hls_values<-cbind(value=raster::extract(hls_ras,site_sp_utm) ,f)
                          print(paste0( band, ", ", f, " out of ", nday))
                          hls_values[complete.cases(hls_values),]
                        },
                        error=function(err) {
                          cbind(value=NA ,f)
                        })
                        
                      }
    
    hls_df_list[[band]]<-hls_mat %>% 
      as_tibble() %>% 
      left_join(time_df, by="f") %>% 
      mutate(band=band)
  }
  
  hls_df_allsite[[s]]<-bind_rows(hls_df_list) %>% 
    spread(key="band", value="value") %>% 
    dplyr::select(-f) %>%
    mutate(site=sitename)
  
  unlink(paste0(outDir, "/", sitename), recursive = T)
} 

stopCluster(cl)

hls_df<-bind_rows(hls_df_allsite)
write_rds(hls_df, "./data/evi ts.rds")

hls_df<-read_rds("./data/evi ts.rds")
hls_df_proc<-hls_df %>% 
  rowwise() %>% 
  mutate(aerosol=(intToBits(Fmask) [1:8] %>% as.integer()) [7:8] %>% str_flatten() %>% as.integer(),
         water=(intToBits(Fmask) [1:8] %>% as.integer()) [6] %>% as.integer(),
         snowice=(intToBits(Fmask) [1:8] %>% as.integer()) [5] %>% as.integer(),
         cloudshadow=(intToBits(Fmask) [1:8]  %>% as.integer()) [3:4] %>% str_flatten() %>% as.integer(),
         cloud=(intToBits(Fmask) [1:8]  %>% as.integer()) [2] %>% as.integer()) %>%  
  ungroup() %>% 
  # mutate(qa=case_when(Fmask==0|Fmask==64 ~2,
  #                     TRUE~1)) %>%
  # filter(qa==2|is.na(qa)) %>%
  filter(aerosol<11,
         water==0,
         snowice==0,
         cloudshadow==0,
         cloud==0) %>%
  dplyr::select(-Fmask, -aerosol, -water, -snowice, -cloudshadow, -cloud) %>%
  group_by(site,  date, year, doy ) %>% 
  summarize(blue=mean(blue),
            green=mean(green),
            red=mean(red),
            nir=mean(nir)) %>% 
  ungroup() %>% 
  mutate(evi=2.5* (nir-red) / (nir + 6*red - 7.5*blue + 1)) %>% 
  filter(evi>0, evi<=1) %>% 
  filter(red>0, green>0, blue>0) 

hls_df_proc %>% 
  ggplot()+
  geom_point(aes(x=date, y=evi), col="darkgreen")+
  theme_classic()+
  facet_wrap(.~site)
