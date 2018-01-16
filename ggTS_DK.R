#### draws a TS diagram using ggplot2
# created by David Kaiser, david.kaiser.82@gmail.com
# in prep:
# write isopycnal values on the top as well (currently only on the right)
# blabla this is a test

# argument
ggTS_DK <- function(
  sal, # vector of salinity values
  pot.temp, # vector of potential temperature values in degree C
  reference.p = 0, # reference pressure which was also used to calculate potential temperature, defaults to 0
  col.par = NA, # optional vector corresponding to "sal" and "pot.temp" of a parameter to be displayed as color along the 
  col.name = "col.par" # optional name of the "col.par" to be used on the color bar
  ) 
  {
  # packages
  require(gsw)
  require(ggplot2)
  
  # make TS long table
  TS <- expand.grid(
    sal = seq(floor(min(sal)), ceiling(max(sal)), length.out = 100),
    pot.temp = seq(floor(min(pot.temp)), ceiling(max(pot.temp)), length.out = 100)
  )
  TS$density <- gsw_rho_t_exact(SA = TS$sal, t = TS$pot.temp, p = reference.p) - 1000 # the function calculates in-situ density, but because potential temperature and a single reference pressure is used the result equals potential density at reference pressure
  
  # isopycnal lables
  isopycnals <- subset(TS,
                       sal == ceiling(max(TS$sal)) & # selects all rows where "sal" is the max limit of the x axis
                       round(density,1) %in% seq(min(round(TS$density*2)/2), 
                                       max(round(TS$density*2)/2), 
                                       by = .5)) # selects any line where the rounded denisty is equal to density represented by any isopycnal in the plot
  isopycnals$density <- round(isopycnals$density, 1) # rounds the density
  isopycnals <- aggregate(pot.temp~density, isopycnals, mean) # reduces number of "pot.temp" values to 1 per each unique "density" value

  # data
  data <- data.frame(sal, pot.temp, col.par)  
  
  # plot
  p1 <- ggplot() +
    geom_contour(data = TS,aes(x = sal, y = pot.temp, z = density), col = "grey", linetype = "dashed",
                 breaks = seq(min(round(TS$density*2)/2), # taking density times 2, rounding and dividing by 2 rounds it to the neares 0.5
                              max(round(TS$density*2)/2), 
                              by = .5)) +
    geom_point(data = data[is.na(data$col.par),], # plot NA values in black to show resolution of "pot.temp" and "sal"
               aes(sal, pot.temp), color = "black") +
    geom_path(data = data, aes(sal, pot.temp), color = "black") +
    geom_point(data = data[!is.na(data$col.par),], # plot only the points that have a z value in color according to z
               aes(sal, pot.temp, color = col.par)) +   
    geom_text(data = isopycnals, 
              aes(x = ceiling(max(TS$sal)), y = pot.temp, label = density),
              hjust = "inward", vjust = 0, col = "grey") +
    annotate(geom = "text", x = floor(min(TS$sal)), y = ceiling(max(TS$pot.temp)), 
             hjust = "inward", vjust = "inward", color = "grey60", size = 14,
             label = paste0('sigma',"[",reference.p,"]"), parse = T) +
    scale_x_continuous(name = "salinity", expand = c(0,0), 
                       limits = c(floor(min(TS$sal)), ceiling(max(TS$sal)))) + # use range of "sal" for x axis
    scale_y_continuous(name = "potential termperature [°C]", 
                       limits = c(floor(min(TS$pot.temp)), ceiling(max(TS$pot.temp)))) + # use range of "pot.temp" for y axis
    scale_color_gradientn(colors = c("blue", "green", "yellow", "red"), name = col.name) +
    theme_classic() + theme(text = element_text(size=14))
  return(p1)
}

# example
test <- H4_complete[H4_complete$station==41,]
ggTS_DK(sal = test$sal00, 
        pot.temp = test$potemp090C, 
        reference.p = 0, 
        col.par = test$DOC.µM, 
        col.name = "depth [m]") 

# Test, if I am allowed to push into the master branch