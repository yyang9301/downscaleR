# What is downscaleR?

**downscaleR** is an R package for empirical-statistical downscaling focusing on daily data and covering the most popular approaches (bias correction, Model Output Statistics, Perfect Prognosis) and techniques (e.g. quantile mapping, regression, analogs, neural networks). This package has been conceived to work in the framework of both seasonal forecasting and climate change studies. Thus, it considers ensemble members as a basic dimension of the data structure. Find out more about this package at the [downscaleR wiki](https://github.com/SantanderMetGroup/downscaleR/wiki). 

This package is part of the [climate4R bundle](http://www.meteo.unican.es/climate4r), formed by `loadeR`, `transformeR`, `downscaleR` and `visualizeR`. The recommended installation procedure is to use the `install_github` command from the devtools R package:

```r
devtools::install_github(c("SantanderMetGroup/transformeR", "SantanderMetGroup/downscaleR"))
```
**NOTE:** Note that `transformeR` is a dependency for `downscaleR`. The utilities in `transformeR` were formerly part of `downscaleR` (up to v1.3-4). Since `downscaleR` v2.0-0, these are in `transformeR` and `downscaleR` is strictly aimed to statistical downscaling. Note that `transformeR` also includes illustrative datasets for the `climate4r`framework.

**EXAMPLE:** The following code trains three different downscaling methods (analogs, linear regression and neural networks) using principal components (explaining 95\% of the variance for each variable) and visualizes the results (the illustrative station and reanalysis data for DJF included in the `transformeR` package is used in this example): 
```r
library(downscaleR)
data("VALUE_Iberia_tas") # illustrative datasets included in transformeR
y <- VALUE_Iberia_tas 
data("NCEP_Iberia_hus850", "NCEP_Iberia_psl", "NCEP_Iberia_ta850")
x <- makeMultiGrid(NCEP_Iberia_hus850, NCEP_Iberia_psl, NCEP_Iberia_ta850)
# calculating predictors
data <- prepareData(x = x, y = y,spatial.predictors = list(v.exp = 0.95)) 
# Fitting statistical downscaling methods (simple case, no cross-validation)
analog <- downscale.train(data, method = "analogs", n.analogs = 1)
regression <- downscale.train(data, method = "GLM",family = gaussian)
neuralnet <- downscale.train(data, method = "NN", hidden = c(10,5), output = "linear")
# Extracting the results for a particula station (Igueldo) for a single year (2000)
igueldo.2000 <- subsetGrid(y,station.id = "000234",years = 2000)
analog.2000 <- subsetGrid(analog$pred,station.id = "000234",years = 2000)
regression.2000 <- subsetGrid(regression$pred,station.id = "000234",years = 2000)
neuralnet.2000 <- subsetGrid(neuralnet$pred,station.id = "000234",years = 2000)
library(visualizeR)  # Data visualization utilities
temporalPlot(igueldo.2000, analog.2000, regression.2000, neuralnet.2000)
```

---
Reference and further information: 

**[General description of the climate4R framework]** Iturbide et al. (2019) The R-based climate4R open framework for reproducible climate data access and post-processing. **Environmental Modelling and Software**, 111, 42-54. https://doi.org/10.1016/j.envsoft.2018.09.009
Check out the companion notebooks for the two examples [GitHub](https://github.com/SantanderMetGroup/notebooks).

**[Seasonal forecasting applications]** Cofiño et al. (2018) The ECOMS User Data Gateway: Towards seasonal forecast data provision and research reproducibility in the era of Climate Services. **Climate Services**, 9, 33-43. http://doi.org/10.1016/j.cliser.2017.07.001


