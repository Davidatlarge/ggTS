#### draws a TS diagram using ggplot2
# created by David Kaiser

# arguments
ggTS <- function(
  sal, # vector of salinity values
  pot.temp, # vector of potential temperature values in degree C
  reference.p = 0, # reference pressure which was also used to calculate potential temperature, defaults to 0
  col.par = NA, # optional vector corresponding to "sal" and "pot.temp" of a parameter to be displayed as color along the 
  col.name = "col.par" # optional name of the "col.par" to be used on the color bar
  ) 
  {
  # packages
  library(gsw)
  library(ggplot2)
  
  # make TS long table
  TS <- expand.grid(
    sal = seq(floor(min(sal, na.rm = TRUE)), ceiling(max(sal, na.rm = TRUE)), length.out = 100),
    pot.temp = seq(floor(min(pot.temp, na.rm = TRUE)), ceiling(max(pot.temp, na.rm = TRUE)), length.out = 100)
  )
  TS$density <- gsw_rho_t_exact(SA = TS$sal, t = TS$pot.temp, p = reference.p) - 1000 # the function calculates in-situ density, but because potential temperature and a single reference pressure is used the result equals potential density at reference pressure
  
  # isopycnal labels 
  # +- horizontal isopycnals
  h.isopycnals <- subset(TS,
                         sal == ceiling(max(TS$sal)) & # selects all rows where "sal" is the max limit of the x axis
                           round(density,1) %in% seq(min(round(TS$density*2)/2, na.rm = TRUE),
                                                     max(round(TS$density*2)/2, na.rm = TRUE),
                                                     by = .5)) # selects any line where the rounded denisty is equal to density represented by any isopycnal in the plot
  if(nrow(h.isopycnals)>0){
    h.isopycnals$density <- round(h.isopycnals$density, 1) # rounds the density
    h.isopycnals <- aggregate(pot.temp~density, h.isopycnals, mean) # reduces number of "pot.temp" values to 1 per each unique "density" value
  }
  
  # +- vertical isopycnals
  if(nrow(h.isopycnals)==0){ # if the isopycnals are not +- horizontal then the df will have no rows
    rm(h.isopycnals) # remove the no-line df
    
    v.isopycnals <- subset(TS, # make a df for labeling vertical isopycnals
                           pot.temp == ceiling(max(TS$pot.temp)) & # selects all rows where "sal" is the max limit of the x axis
                             round(density,1) %in% seq(min(round(TS$density*2)/2),
                                                       max(round(TS$density*2)/2),
                                                       by = .5)) # selects any line where the rounded denisty is equal to density represented by any isopycnal in the plot
    v.isopycnals$density <- round(v.isopycnals$density, 1) # rounds the density
    v.isopycnals <- aggregate(sal~density, v.isopycnals, mean) # reduces number of "pot.temp" values to 1 per each unique "density" value
  }
  
  # data
  data <- data.frame(sal, pot.temp, col.par)  
  
  # plot
  p1 <- ggplot() +
    geom_contour(data = TS, aes(x = sal, y = pot.temp, z = density), col = "grey", linetype = "dashed",
                 breaks = seq(min(round(TS$density*2)/2, na.rm = TRUE), # taking density times 2, rounding and dividing by 2 rounds it to the neares 0.5
                              max(round(TS$density*2)/2, na.rm = TRUE), 
                              by = .5)) +
    geom_point(data = data[is.na(data$col.par),], # plot NA values in black to show resolution of "pot.temp" and "sal"
               aes(sal, pot.temp), color = "black") +
    geom_path(data = data, aes(sal, pot.temp), color = "black") +
    geom_point(data = data[!is.na(data$col.par),], # plot only the points that have a z value in color according to z
               aes(sal, pot.temp, color = col.par)) +   
    annotate(geom = "text", x = floor(min(TS$sal, na.rm = TRUE)), y = ceiling(max(TS$pot.temp, na.rm = TRUE)), 
             hjust = "inward", vjust = "inward", color = "grey60", size = 14,
             label = paste0('sigma',"[",reference.p,"]"), parse = T) +
    scale_x_continuous(name = "salinity", expand = c(0,0), 
                       limits = c(floor(min(TS$sal, na.rm = TRUE)), ceiling(max(TS$sal, na.rm = TRUE)))) + # use range of "sal" for x axis
    scale_y_continuous(name = "potential temperature [°C]", 
                       limits = c(floor(min(TS$pot.temp, na.rm = TRUE)), ceiling(max(TS$pot.temp, na.rm = TRUE)))) + # use range of "pot.temp" for y axis
    scale_color_gradientn(colors = c("blue", "green", "yellow", "red"), name = col.name) +
    theme_classic() + theme(text = element_text(size=14))
  
  # add isopycnal labels if isopycnals run +- horizontal
  if(exists("h.isopycnals")){
    p1 <- p1 + geom_text(data = h.isopycnals,
                         aes(x = ceiling(max(TS$sal)), y = pot.temp, label = density),
                         hjust = "inward", vjust = 0, col = "grey")
  }
  
  # add isopycnal labels if isopycnals run +- vertical
  if(exists("v.isopycnals")){
    p1 <- p1 + geom_text(data = v.isopycnals,
                         aes(x = sal, y = ceiling(max(TS$pot.temp)), label = density),
                         hjust = "inward", vjust = 0, col = "grey")
  }

  return(p1)
}
