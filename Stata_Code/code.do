* Install package outreg2
ssc install outreg2

* Creating a global to the directory
global datadir "C:/Users/João Reis/Desktop/Assignment2_Data4"

* Creating a new directory to save the raw .csv data as .dta data, so we can append them easily later
capture mkdir "$datadir/Datasets_Stata"
global datasets "$datadir/Datasets_Stata"

* Creating a new directory to save the outputs from the analysis
capture mkdir "$datadir/Output"
global output "$datadir/Output"


*-------------------------------------------- SECOND PART: Convert data from .csv to .dta --------------------------------------------* 


* Importing the files as .csv and saving them as .dta
import delimited "${datadir}/Datasets/CO2_emissions", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/CO2_emissions.dta", replace

import delimited "${datadir}/Datasets/GDP_per_capita", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/GDP_per_capita.dta", replace

*-------------------------------------------- THIRD PART: Importing and cleaning each dataset --------------------------------------------* 

* CO2 Emissions Dataset
use "${datasets}/CO2_emissions.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long yr, i(countrycode) j(year)
rename yr CO2emissions
drop seriesname
drop seriescode

* Saving the data
save "${datasets}/CO2_emissions", replace

* GDP per capita Dataset
use "${datasets}/GDP_per_capita.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long yr, i(countrycode) j(year)
rename yr gdppercapita
drop seriesname
drop seriescode

* Saving the data
save "${datasets}/GDP_per_capita", replace

*-------------------------------------------- THIRD PART: Merging both datasets and cleaning the data for regressions --------------------------------------------* 

merge 1:1 countrycode year countryname using "${datadir}/Datasets_Stata/CO2_emissions"
drop _merge

* Transforming the GDP and CO2 variables from string to float so I can do analysis with it
generate CO2_emissions = real(CO2emissions)
generate gdp_per_capita = real(gdppercapita)

label variable CO2_emissions "CO2 emissions (metric tons per capita)"
label variable gdp_per_capita "GDP per capita, PPP (constant 2017 international $)"

drop CO2emissions
drop gdppercapita

* Balancing the panel
egen n_CO2=count(CO2_emissions), by(countrycode)
egen n_gdp=count(gdp_per_capita), by(countrycode)

tab countryname if n_CO2<27, sum(n_CO2)
drop if n_CO2 < 27

tab countryname if n_gdp<27, sum(n_gdp)
drop if n_gdp < 24	

/* Add missing values to the countries that had less than 27 but at least 24 observations for the GDP_per_capita. The reason to such imputations is my belief that the missing data is not random, but it is related with countries specifics (as it is observable, the most are ex-USSR and ex-Juguslavia countries). Thus, I believe that dropping those observations would generate a strong bias in the model, not only due to the ammount of observations, but do to their nature.
To input the missing data I considered that the growth rate in the first years of observation was constant. Therefore, I calculated the growth_rate and used the first growth_rate available to compute the missing GDP_per_capita values (backwards process). Such assumption is debatable, mainly due to the socioeconomic instability during these years in the ex-socialist countries. However, I believe the data will not widely diverge from its original values, and I argue that the harm to the estimation would be bigger if those observations were dropped instead (mainly when studying the relation between GDP and CO2 emissions, ex-soviet countries have a lot of specifics that can impact the results)
*/

gen growth_rate = (gdp_per_capita[_n]/gdp_per_capita[_n-1] - 1) if year != 1992

local i = 1
while `i' < 4{
  replace gdp_per_capita = gdp_per_capita[_n+1]/(1+growth_rate[_n+2]) if missing(gdp_per_capita)
  replace growth_rate = (gdp_per_capita[_n]/gdp_per_capita[_n-1] - 1) if year != 1992
  local i = `i' +1
}

* Droping auxiliar variables (no more needed)
drop n_CO2
drop n_gdp

save "${datasets}/final_dataset", replace

*-------------------------------------------- THIRD PART: Analyzing and preparing the data for regressions --------------------------------------------* 

* Transforming the countrycode into a numeric variable so I can set a panel data in Stata. I am not going to drop countrycode since it is not possible to do conditions based on countryid - it is numeric - and sometimes to know the countrycode is easier than to know the country name 
encode countrycode, gen(countryid)

* Transforming the dataset into a panel data
xtset countryid year
xtdes

* Just computing some twowat plots to check if data is according to the expected or if there is strange things going on. Countries that represent different realities: 
twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Austria",  xsize(100) ysize(45) title("United States of America")
graph export "$output\twoway_us.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Austria",  xsize(100) ysize(45) title("Austria")
graph export "$output\twoway_austria.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Portugal",  xsize(100) ysize(45) title("Portugal")
graph export "$output\twoway_portugal.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Mozambique",  xsize(100) ysize(45) title("Mozambique")
graph export "$output\twoway_mozambique.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Angola",  xsize(100) ysize(45) title("Angola")
graph export "$output\twoway_angola.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "Brazil",  xsize(100) ysize(45) title("Brazil")
graph export "$output\twoway_brazil.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "China",  xsize(100) ysize(45) title("China")
graph export "$output\twoway_china.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions , yaxis(2)) || if countryname == "India",  xsize(100) ysize(45) title("India")
graph export "$output\twoway_india.png",replace

* Generating the Natural Logarithms of both variables
gen ln_gdp_per_capita = ln(gdp_per_capita)
gen ln_CO2_emissions = ln(CO2_emissions)

label var ln_gdp_per_capita "Natural logarithm of GDP per Capita"
label var ln_CO2_emissions "Natural logarithm of CO2 Emissions per Capita"

* Creating first diferences of the variables *
gen d_gdp_per_capita = d.gdp_per_capita
gen d_ln_gdp_per_capita = d.ln_gdp_per_capita
gen d_CO2_emissions = d.CO2_emissions
gen d_ln_CO2_emissions = d.ln_CO2_emissions

label var d_gdp_per_capita "First Differences of GDP per Capita"
label var d_ln_gdp_per_capita "First Differences of Natural Logarithm of GDP per Capita"
label var d_CO2_emissions "First Differences of CO2 Emissions per Capita"
label var d_ln_CO2_emissions "First Differences of Natural Logarithm of CO2 emissions per Capita"

sum gdp_per_capita, detail
sum ln_gdp_per_capita, detail
sum CO2_emissions, detail 
sum ln_CO2_emissions, detail
sum d_gdp_per_capita, detail
sum d_ln_gdp_per_capita, detail
sum d_CO2_emissions, detail
sum d_ln_CO2_emissions, detail

*-------------------------------------------- THIRD PART: Regressions --------------------------------------------* 

* OLS Regressions *

* 1)
reg CO2_emissions gdp_per_capita if year == 1992

reg CO2_emissions ln_gdp_per_capita if year == 1992

reg ln_CO2_emissions gdp_per_capita if year == 1992

reg ln_CO2_emissions ln_gdp_per_capita if year == 1992

*2)
reg CO2_emissions gdp_per_capita if year == 2018

reg CO2_emissions ln_gdp_per_capita if year == 2018

reg ln_CO2_emissions gdp_per_capita if year == 2018

reg ln_CO2_emissions ln_gdp_per_capita if year == 2018

* FD REGRESSIONS *




