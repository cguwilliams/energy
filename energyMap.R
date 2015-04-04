###Combining Census data with a tract poly shapefile
library(maptools)
library(ggplot2)
library(gpclib)
library(RColorBrewer)
library(ggmap)
library(rgdal)
library(dplyr)

#quantile cut variable for quantizing data for display
qcut <- function(x, n) {
        cut(x, quantile(x, seq(0, 1, length = n + 1),na.rm=T), labels = seq_len(n),
            include.lowest = TRUE)
}
setwd('~/Documents/GIS/energy_usage/Boundaries_-_Census_Blocks_-_2010/')
#Read data
tract = readOGR(".","CensusBlockTIGER2010") %>% spTransform(CRS("+proj=longlat +datum=WGS84"))
# tract<-readShapePoly('./Boundaries_-_Census_Blocks_-_2010/CensusBlockTIGER2010.shp')
cdata<-read.csv('../Energy_Usage_2010.csv')

#Columns >> note that GEOID (tract) and geoid2 (cdata) are the merge keys
ntract<-names(tract)
ncdata<-names(cdata) 

#Fix ncdata column names
newnames <- ncdata               #Create temporary vector of names to work on
newnames <- tolower(newnames)           #Make all column names lowercase
newnames <- gsub("\\.","",newnames)     #Remove all '.' characters, which must be escaped with \ (which itself must be escaped with another \)
ncdata <- newnames  
names(cdata) <- ncdata

#Prepare data for ggplot plotting of poly info (by conversion to DataFrame)
gpclibPermit()
tract_geom<-fortify(tract,region="GEOID10")

#Merge
tract_poly<-merge(tract_geom,cdata,by.x="id",by.y="censusblock")
tract_poly<-tract_poly[order(tract_poly$order),]

toplot <- 'thermmean2010'
tract_poly$value  <- qcut(tract_poly[[toplot]],9)
# tract_poly2 <- tract_poly[tract_poly$long>-87.7974446344,]

large_map <- get_stamenmap(bbox = c(left = -87.885169, bottom=41.643919,
                                    right = -87.523984, top = 42.023022),
                             zoom=13,maptype="watercolor")

# crop_map <- get_stamenmap(bbox = c(left = -87.605358,
#                                     bottom = 41.794957,
#                                     right = -87.565261,
#                                     top = 41.80666),
#                            zoom=16,maptype="watercolor")

chicagoheat <- ggmap(large_map,extent='device') +
#         geom_polygon(aes(x = long, y = lat, group = group, fill = value),
#                      alpha = .7,
#                      data = tract_poly) +
#         scale_fill_manual(values=rev(brewer.pal(9,"YlOrRd"))) +
#         coord_map() +
        theme(legend.position="none",panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              panel.background = element_blank(), axis.line = element_line(color = NA),
              axis.text = element_blank (),axis.ticks = element_blank(), axis.title = element_blank())

png("chicagowatercolor.png", width = 2.5, height = 4.5, units = 'in', res = 300)
chicagoheat
dev.off()
