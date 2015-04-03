#Mapping energy usage in Chicago. 

The map below represents a zoomed in version of a larger map of mean thermal units of energy used by census block in the city of chicago. The full map is shown at the bottom of this ReadMe.
<a href="url"><img src="http://home.uchicago.edu/~pbwilliams/images/upperhyde.png" align="left" height="350" ></a><br>

The map was made natively in R, with RStudio, using several R libraries. It was developed for two purposes:

1. To get familiar with GIS tools in the R language
2. To begin an investigation of the relationship between crime in Chicago, and possible underlying factors such as population, energy consumption, income, and green space.

I would like to step through how this map was created, for anyone who may be interested in similar projects.

##Data acquisition
Data for this project were acquired from two sources:
- Energy Data: [Chicago Public Data Portal] (https://data.cityofchicago.org/)
- Chicago census tracts: [Census Tract Shape Files](https://www.census.gov/geo/maps-data/data/tiger-line.html)
- [Stamenmaps](http://maps.stamen.com/#toner/12/37.7706/-122.3782). From within R.
- 
With these data in hand, I read each into R and began processing and eventual visualization. This process can be completed using other software, such as QGIS and Tilemill. Each software has its advantages but I liked doing it all in R because it was self-contained and allowed a high degree of control over parameters.

##The code
loading packages
```
###Combining Census data with a tract poly shapefile
library(maptools)
library(ggplot2)
library(gpclib)
library(RColorBrewer)
library(ggmap)
library(rgdal)
library(dplyr)
```
Load one helper function for later
```
#quantile cut variable for quantizing data for display
qcut <- function(x, n) {
        cut(x, quantile(x, seq(0, 1, length = n + 1),na.rm=T), labels = seq_len(n),
            include.lowest = TRUE)
}
```
Load and cleanup data (your filepath will differ). For this particular code, your shapefile and data file should be in the same directory.
```
#First load the census tract shape file
setwd('~/Documents/GIS/energy_usage/Boundaries_-_Census_Blocks_-_2010/')
#Read data
tract = readOGR(".","CensusBlockTIGER2010") %>% spTransform(CRS("+proj=longlat +datum=WGS84"))
#Now load the energy data
cdata<-read.csv('Energy_Usage_2010.csv')

#store column names for both datasets in variables
ntract<-names(tract)
ncdata<-names(cdata) 

#Fix ncdata column names to be more readable
newnames <- ncdata               #Create temporary vector of names to work on
newnames <- tolower(newnames)           #Make all column names lowercase
#Remove all '.' characters, which must be escaped with \ (which itself must be escaped with another \)
newnames <- gsub("\\.","",newnames)     
ncdata <- newnames  
names(cdata) <- ncdata
```
the fortify command will transform your shape file into something that R can work with more directly. Following fortify  
your shape and energy data may be merged along the unique id, which in this case, is the census tract id (a 15 digit number).
```
#Prepare data for ggplot plotting of poly info (by conversion to DataFrame)
gpclibPermit()
tract_geom<-fortify(tract,region="GEOID10")

#Merge
tract_poly<-merge(tract_geom,cdata,by.x="id",by.y="censusblock")
tract_poly<-tract_poly[order(tract_poly$order),]
```
The choice to plot the mean of thermal data here was somewhat arbitrary. Other choices were raw thermal energy, as well
as electricity usage. While I visualized annual data, there are also columns for each month and quarter of the year. This  
richness of data can lead to a lot of interesting visualizations and importantly, idea generation!
```
toplot <- 'thermmean2010' #This is where you select your variable of interest
```
the qcut function (defined early in the script) will cut up your variable into quantiles. This will change the
gradiation of your visualization (more will be smoother). I picked nine because that was the length of the number of colors 
in the Brewer palette I used.
```
tract_poly$value  <- qcut(tract_poly[[toplot]],9) 
#Map of the city of Chicago, as a 'watercolor' stamenmap. I chose this for its artistic style
large_map <- get_stamenmap(bbox = c(left = -87.885169, bottom=41.643919,
                                    right = -87.523984, top = 42.023022),
                             zoom=13,maptype="toner")
ggplot(large_map)
```
the base 'watercolor' map alone looks very styled, and for any serious purposes should probably use something more subdued. I chose the watercolor map and zoomed into a small radius around my house to make a good looking header for my webpage (displayed here as a preview). A 'toner' or 'terrain' map is much more informative, and carries more contrast against the colors used in the map.
<br>
<br>
##Plotting the data

Now we will plot the data:
```
chicagoheat <- ggmap(large_map,extent='device') +
        geom_polygon(aes(x = long, y = lat, group = group, fill = value),
                     alpha = .7,
                     data = tract_poly) +
        scale_fill_manual(values=rev(brewer.pal(9,"YlOrRd"))) +
        coord_map() +
        geom_point(colour = "black",size=1.5,aes(x = longitude, y = latitude),
                   data = violent_crimes) +
        theme(legend.position="none",panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              panel.background = element_blank(), axis.line = element_line(color = NA),
              axis.text = element_blank (),axis.ticks = element_blank(), axis.title = element_blank())

chicagoheat
```
While we have not worked in any other variable of interest at this time, it is a very cool looking map, and we can see that it looks about as expected if you know anything about the North-South, East-West devides of Chicago, and the brightest colors are downtown. I haven't plotted the legend in this version, but yellow corresponds to greater mean thermal units, while red corresponds to fewer mean thermal units. 

I am now working to add additional layers, such as points of crime in the city, as well as to create a spreadsheet which can be used for explaining relationships among city-based variables. This is a unique challenge, as for example, energy is binned by census tract ID, while crime can at best best binned by community. It will be important to find a common way to bin them to look at relationships, while maintaining a high degree of granularity (there are over 36,000 census tracts to look at, while there are only around 70 communities in Chicago). The challengest are part of the fun and will update as more data are analyzed.

Here is what the map looks like. It's highly stylized for now, but that can be easily modified as more serious analyses move forward. It has also been slightly cropped from the full-size.

<a href="url"><img src="http://home.uchicago.edu/~pbwilliams/images/chicagoheat.png" align="left" height="560" ></a>



