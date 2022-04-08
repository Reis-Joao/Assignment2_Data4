*-------------------------------------------- FIRST PART: Settings --------------------------------------------* 

* Ignore this step, it is just my Stata that does not let me install packages if I do not do that for some reason
sysdir set PLUS "C:/Users/João Reis/Desktop" 

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

import delimited "${datadir}/Datasets/GDP_PPP", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/GDP_PPP.dta", replace

import delimited "${datadir}/Datasets/Population", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/Population.dta", replace

import delimited "${datadir}/Datasets/Renewable_Energy", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/Renewable_Energy.dta", replace

import delimited "${datadir}/Datasets/Urban_Population", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/Urban_Population.dta", replace

import delimited "${datadir}/Datasets/Forest_Area", clear varnames(1) bindquotes(strict) encoding("utf-8")
save "${datasets}/Forest_Area.dta", replace

*-------------------------------------------- THIRD PART: Importing and cleaning each dataset --------------------------------------------* 

* -----> 1) CO2 Emissions Dataset
use "${datasets}/CO2_emissions.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Destring the variables
forvalues i = 1992(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ CO2_emissions
drop seriesname
drop seriescode

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/CO2_emissions", replace

* -----> 2) GDP PPP Dataset
use "${datasets}/GDP_PPP.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Destring the variables
forvalues i = 1992(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ gdp_ppp
drop seriesname
drop seriescode

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/GDP_PPP.dta", replace

* -----> 3) Population Dataset
use "${datasets}/Population.dta", clear

* Destring the variables
forvalues i = 1992(1)1994{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

forvalues i = 1995(1)2011{
	rename yr`i' year_`i'
}

forvalues i = 2012(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Dropping extra information not needed
drop if missing(countrycode)

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ population
drop seriesname
drop seriescode

format population %12.0f

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/Population", replace

* -----> 4) Renewable Energy Dataset
use "${datasets}/Renewable_Energy.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Destring the variables
forvalues i = 1992(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ renewable_energy
drop seriesname
drop seriescode

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/Renewable_Energy", replace

* -----> 5) Urban Population Dataset
use "${datasets}/Urban_Population.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Destring the variables
forvalues i = 1992(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ urban_population
drop seriesname
drop seriescode

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/Urban_Population", replace

* -----> 6) Forest Area Dataset
use "${datasets}/Forest_Area.dta", clear

* Dropping extra information not needed
drop if missing(countrycode)

* Destring the variables
forvalues i = 1992(1)2018{
	generate year_`i' = real(yr`i')
	drop yr`i'
}

* Reshape the dataset and doing some minor adjustments to be more readable
reshape long year_, i(countrycode) j(year)
rename year_ forest_area
drop seriesname
drop seriescode

order countryname, after(countrycode)
sort countrycode countryname year

* Saving the data
save "${datasets}/Forest_Area", replace

*-------------------------------------------- FOURTH PART: Merging both datasets and cleaning the data for regressions --------------------------------------------* 

merge 1:1 countrycode year countryname using "${datadir}/Datasets_Stata/CO2_emissions", nogenerate
merge 1:1 countrycode year countryname using "${datadir}/Datasets_Stata/GDP_PPP", nogenerate
merge 1:1 countrycode year countrycode using "${datadir}/Datasets_Stata/Population", nogenerate
merge 1:1 countrycode year countrycode using "${datadir}/Datasets_Stata/Renewable_Energy", nogenerate
merge 1:1 countrycode year countrycode using "${datadir}/Datasets_Stata/Urban_Population", nogenerate

* Generate GDP Per Capita
generate gdp_per_capita = gdp_ppp / population
generate CO2_emissions_per_capita = CO2_emissions / population

order gdp_per_capita, after(gdp_ppp)
order CO2_emissions_per_capita, after(CO2_emissions)
order forest_area, after(urban_population)

label variable CO2_emissions "Total CO2 emissions (thousand metric tons of CO2 excluding Land-Use Change and Forestry)"
label variable gdp_ppp "GDP, PPP (constant 2017 international $)"
label variable population "Total Popluation"
label variable gdp_per_capita "GDP per capita, PPP (constant 2017 international $)"
label variable CO2_emissions_per_capita "CO2 emissions per capita (thousand metric tons)"
label variable renewable_energy "Renewable energy consumption (% of total final energy consumption)"
label variable urban_population "Urban population"
label variable forest_area "Forest area (sq. km)"

* Balancing the panel on the key variables
egen n_CO2=count(CO2_emissions_per_capita), by(countrycode)
egen n_gdp=count(gdp_per_capita), by(countrycode)

tab countryname if n_CO2<27, sum(n_CO2)
tab countryname if n_gdp<27, sum(n_gdp)

* Since a considerable number of countries have 24 observations (starting in 1995), and since these countries are not totally random (a lot of ex-soviet/yugoslavia countries), I decided to start my analysis in 1995

drop if year < 1995

drop n_CO2 n_gdp 

egen n_CO2 = count(CO2_emissions_per_capita), by(countrycode)
egen n_gdp = count(gdp_per_capita), by(countrycode)

tab countryname if n_CO2<24, sum(n_CO2)
drop if n_CO2 < 24

tab countryname if n_gdp<24, sum(n_gdp)
drop if n_gdp < 24

* Droping auxiliar variables (no longer needed)
drop n_CO2 n_gdp

* Balancing the panel on the confounders
egen n_population = count(population), by(countrycode)
egen n_renewable_energy = count(renewable_energy), by(countrycode)
egen n_urban_population = count(urban_population), by(countrycode)
egen n_forest_area = count(forest_area), by(countrycode)

tab countryname if n_population < 24, sum(n_population)
tab countryname if n_renewable_energy < 24, sum(n_renewable_energy)
tab countryname if n_urban_population < 24, sum(n_urban_population)
tab countryname if n_forest_area < 24, sum(n_forest_area)

drop if n_population < 24 | n_renewable_energy < 24 | n_urban_population < 24 | n_forest_area < 24 /* Since only 3 countries had not complete observations for the time period considered, I have decided to drop them */

* Droping auxiliar variables (no longer needed)
drop n_population n_renewable_energy n_urban_population n_forest_area

save "${datasets}/final_dataset", replace

*-------------------------------------------- FIFTH PART: Analyzing and preparing the data for regressions --------------------------------------------* 

* Transforming the countrycode into a numeric variable so I can set a panel data in Stata. I am not going to drop countrycode since it is not possible to do conditions based on countryid - it is numeric - and sometimes to know the countrycode is easier than to know the country name 
encode countrycode, gen(countryid)
order countryid, after(countrycode)

* Transforming the dataset into a panel data
xtset countryid year
xtdes

* Just computing some twowat plots to check if data is according to the expected or if there is strange things going on. Countries that represent different realities: 
twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Austria",  xsize(100) ysize(45) title("United States of America")
graph export "$output\twoway_us.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Austria",  xsize(100) ysize(45) title("Austria")
graph export "$output\twoway_austria.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Portugal",  xsize(100) ysize(45) title("Portugal")
graph export "$output\twoway_portugal.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Mozambique",  xsize(100) ysize(45) title("Mozambique")
graph export "$output\twoway_mozambique.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Angola",  xsize(100) ysize(45) title("Angola")
graph export "$output\twoway_angola.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "Brazil",  xsize(100) ysize(45) title("Brazil")
graph export "$output\twoway_brazil.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "China",  xsize(100) ysize(45) title("China")
graph export "$output\twoway_china.png",replace

twoway (tsline gdp_per_capita , yaxis(1)) || (tsline CO2_emissions_per_capita , yaxis(2)) || if countryname == "India",  xsize(100) ysize(45) title("India")
graph export "$output\twoway_india.png",replace

* Generating the Natural Logarithms of the variables
gen ln_gdp_per_capita = ln(gdp_per_capita)
gen ln_CO2_emissions_per_capita = ln(CO2_emissions)
gen ln_population = ln(population)
gen ln_urban_population = ln(urban_population)
gen ln_forest_area = ln(forest_area)

label var ln_gdp_per_capita "Natural logarithm of GDP per Capita"
label var ln_CO2_emissions_per_capita "Natural logarithm of CO2 Emissions per Capita"
label var ln_population "Natural logarithm of Total Popluation"
label var ln_urban_population "Natural logarithm of Urban Population"
label var ln_forest_area "Natural logarithm of Forest Area (sq. km)"

* Creating first diferences of the variables *
gen d_gdp_per_capita = d.gdp_per_capita
gen d_ln_gdp_per_capita = d.ln_gdp_per_capita
gen d_CO2_emissions_per_capita = d.CO2_emissions_per_capita
gen d_ln_CO2_emissions_per_capita = d.ln_CO2_emissions_per_capita
gen d_population = d.population
gen d_ln_population = d.ln_population
gen d_urban_population = d.urban_population
gen d_ln_urban_population = d.ln_urban_population
gen d_forest_area = d.forest_area
gen d_ln_forest_area = d.ln_forest_area
gen d_renewable_energy = d.renewable_energy

label var d_gdp_per_capita "First Differences of GDP per Capita"
label var d_ln_gdp_per_capita "First Differences of Natural Logarithm of GDP per Capita"
label var d_CO2_emissions_per_capita "First Differences of CO2 Emissions per Capita"
label var d_ln_CO2_emissions_per_capita "First Differences of Natural Logarithm of CO2 emissions per Capita"
label var d_population "First Differences of Total Population"
label var d_ln_population "First Differences of Natural Logarithm of Total Population"
label var d_urban_population "First Differences of Urban Population"
label var d_ln_urban_population "First Differences of Natural Logarithm of Urban Population"
label var d_forest_area "First Differences of Forest Area"
label var d_ln_forest_area "First Differences of Natural Logarithm of Forest Area"
label var d_renewable_energy "First Differences of Renewable Energy"

* Some summaries of the variables: not all are important, but I am letting it in the code in case one wants to check something in particular *
sum gdp_per_capita, detail
sum CO2_emissions_per_capita, detail 
sum population, detail
sum urban_population, detail
sum forest_area, detail
sum renewable_energy, detail

sum ln_gdp_per_capita, detail
sum ln_CO2_emissions_per_capita, detail
sum ln_population, detail
sum ln_urban_population, detail
sum ln_forest_area, detail

sum d_gdp_per_capita, detail
sum d_CO2_emissions_per_capita, detail
sum d_population, detail
sum d_urban_population, detail
sum d_forest_area, detail
sum d_renewable_energy

sum d_ln_gdp_per_capita, detail
sum d_ln_CO2_emissions_per_capita, detail
sum d_ln_population, detail
sum d_ln_urban_population, detail
sum d_ln_forest_area, detail

*-------------------------------------------- SIXTH PART: Regressions --------------------------------------------* 

*------------------ OLS Regressions ------------------*

* 1)
reg CO2_emissions_per_capita gdp_per_capita if year == 1995 
outreg2 using "$output\ols_co2_gdp", se bdec(3) 2aster tex(fragment) replace ctitle("Year = 1995, CO2 Emissions per Capita")

reg CO2_emissions_per_capita ln_gdp_per_capita if year == 1995
outreg2 using "$output\ols_co2_lngdp", se bdec(3) 2aster tex(fragment) replace ctitle("Year = 1995, CO2 Emissions per Capita")

reg ln_CO2_emissions_per_capita gdp_per_capita if year == 1995
outreg2 using "$output\ols_lnco2_gdp", se bdec(3) 2aster tex(fragment) replace ctitle("Year = 1995, Natural Logarithm CO2 Emissions per Capita")

reg ln_CO2_emissions_per_capita ln_gdp_per_capita if year == 1995
outreg2 using "$output\ols_lnco2_lngdp", se bdec(3) 2aster tex(fragment) replace ctitle("Year = 1995, Natural Logarithm CO2 Emissions per Capita")


*2)
reg CO2_emissions gdp_per_capita if year == 2018
outreg2 using "$output\ols_co2_gdp", se bdec(3) 2aster tex(fragment) append ctitle("Year = 2018, CO2 Emissions per Capita")

reg CO2_emissions ln_gdp_per_capita if year == 2018
outreg2 using "$output\ols_co2_lngdp", se bdec(3) 2aster tex(fragment) append ctitle("Year = 2018, CO2 Emissions per Capita")

reg ln_CO2_emissions gdp_per_capita if year == 2018
outreg2 using "$output\ols_lnco2_gdp", se bdec(3) 2aster tex(fragment) append ctitle("Year = 2018, Natural Logarithm CO2 Emissions per Capita")

reg ln_CO2_emissions ln_gdp_per_capita if year == 2018
outreg2 using "$output\ols_lnco2_lngdp", se bdec(3) 2aster tex(fragment) append ctitle("Year = 2018, Natural Logarithm CO2 Emissions per Capita")

*------------------ FD REGRESSIONS ------------------ *

* Basic FD
reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita c.year [w=population], cluster(countryid)
outreg2 using "$output\fd_co2_gdp_weighted", se bdec(3) 2aster tex(fragment) keep(d_ln_gdp_per_capita) replace ctitle("FD With No Lags, FD Natural logarithm of CO2 Emissions per Capita")

* FD with 2 lags
reg d_ln_CO2_emissions_per_capita L(0/2).d_ln_gdp_per_capita c.year [w=population], cluster(countryid)
outreg2 using "$output\fd_co2_gdp_weighted", se bdec(3) 2aster tex(fragment) keep(L(0/2).d_ln_gdp_per_capita) append ctitle("FD With 2 Lags, FD Natural logarithm of CO2 Emissions per Capita")

* FD with 6 lags
reg d_ln_CO2_emissions_per_capita L(0/6).d_ln_gdp_per_capita c.year [w=population], cluster(countryid)
outreg2 using "$output\fd_co2_gdp_weighted", se bdec(3) 2aster tex(fragment) keep(L(0/6).d_ln_gdp_per_capita) append ctitle("FD With 6 Lags, FD Natural logarithm of CO2 Emissions per Capita")

* Testing if the cumulative coefficient is significant
test d_ln_gdp_per_capita + L.d_ln_gdp_per_capita + L2.d_ln_gdp_per_capita + L3.d_ln_gdp_per_capita + L4.d_ln_gdp_per_capita + L5.d_ln_gdp_per_capita + L6.d_ln_gdp_per_capita = 0

*------------------ FE Regressions ------------------*
egen average_population = mean(population), by(countryid) /* For Weights */
format average_population %12.0f

xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita i.year [w=average_population], fe cluster(countryid) /* ln_CO2_emissions on ln_gdp_per_capita */
outreg2 using "$output\fe_co2_gdp_weighted", se bdec(3) 2aster tex(fragment) keep(ln_gdp_per_capita i.year) replace 

*------------------ Long Difference Model------------------*
bysort countryid : gen ld_ln_CO2_emissions_per_capita = ln_CO2_emissions_per_capita[_N] - ln_CO2_emissions_per_capita[1] /*Generating the difference between the last and the first observation*/
bysort countryid : gen ld_ln_gdp_per_capita = ln_gdp_per_capita[_N] - ln_gdp_per_capita[1] 

reg ld_ln_CO2_emissions_per_capita ld_ln_gdp_per_capita [w=average_population], cluster(countryid)
outreg2 using "$output\ld_co2_gdp_weighted", se bdec(3) 2aster tex(fragment) replace ctitle("Long Difference Model, LD Natural logarithm of CO2 Emissions per Capita")

*------------------ Extra: Confounders ------------------ *

* In OLS Regressions *

reg ln_CO2_emissions_per_capita ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy if year == 1995
outreg2 using "$output\ols_lnco2_lngdp_confounders", se bdec(3) 2aster tex(fragment) replace ctitle("Year = 1995, Natural logarithm of CO2 Emissions per Capita")

reg ln_CO2_emissions_per_capita ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy if year == 2018
outreg2 using "$output\ols_lnco2_lngdp_confounders", se bdec(3) 2aster tex(fragment) append ctitle("Year = 2018, Natural logarithm of CO2 Emissions per Capita")

* In FD Regressions *

* Basic FD
reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy c.year [w=population], cluster(countryid)
outreg2 using "$output\fd_co2_confounders_weighted", se bdec(3) 2aster tex(fragment) keep(d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy) replace ctitle("FD With No Lags, FD Natural logarithm of CO2 Emissions per Capita")

* In FE Regressions *
xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy i.year [w=average_population], fe cluster(countryid) /* ln_CO2_emissions on ln_gdp_per_capita controling for ln_population - year fixed effects changed, meaning part of what previously explained by it is not explained by ln_pop - population grew across time */
outreg2 using "$output\fe_co2_gdp_confounders_weighted", se bdec(3) 2aster tex(fragment) keep(ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy i.year) replace ctitle("Fixed Effects, Natural logarithm of CO2 Emissions per Capita")

* Long Difference Model
bysort countryid : gen ld_ln_population = ln_population[_N] - ln_population[1]
bysort countryid : gen ld_ln_urban_population = ln_urban_population[_N] - ln_urban_population[1]
bysort countryid : gen ld_ln_forest_area = ln_forest_area[_N] - ln_forest_area[1]
bysort countryid : gen ld_renewable_energy = renewable_energy[_N] - renewable_energy[1]

reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy [w=average_population], cluster(countryid)
outreg2 using "$output\ld_co2_gdp_confounders_weighted", se bdec(3) 2aster tex(fragment) replace ctitle("Long Difference Model, LD Natural logarithm of CO2 Emissions per Capita")

*------------------ Robustness: Unweighted Regressions ------------------ *

* Basic FD
reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita c.year, cluster(countryid)
outreg2 using "$output\fd_co2_gdp_unweighted", se bdec(3) 2aster tex(fragment) keep(d_ln_gdp_per_capita) replace ctitle("FD With No Lags, FD Natural logarithm of CO2 Emissions per Capita")

reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy c.year, cluster(countryid)
outreg2 using "$output\fd_co2_confounders_unweighted", se bdec(3) 2aster tex(fragment) keep(d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy) replace ctitle("FD With No Lags, FD Natural logarithm of CO2 Emissions per Capita")

* FD with 2 lags
reg d_ln_CO2_emissions_per_capita L(0/2).d_ln_gdp_per_capita c.year, cluster(countryid)
outreg2 using "$output\fd_co2_gdp_unweighted", se bdec(3) 2aster tex(fragment) keep(L(0/2).d_ln_gdp_per_capita) append ctitle("FD With 2 Lags, FD Natural logarithm of CO2 Emissions per Capita")

* FD with 6 lags
reg d_ln_CO2_emissions_per_capita L(0/6).d_ln_gdp_per_capita c.year, cluster(countryid)
outreg2 using "$output\fd_co2_gdp_unweighted", se bdec(3) 2aster tex(fragment) keep(L(0/6).d_ln_gdp_per_capita) append ctitle("FD With 6 Lags, FD Natural logarithm of CO2 Emissions per Capita")

* Testing if the cumulative coefficient is significant
test d_ln_gdp_per_capita + L.d_ln_gdp_per_capita + L2.d_ln_gdp_per_capita + L3.d_ln_gdp_per_capita + L4.d_ln_gdp_per_capita + L5.d_ln_gdp_per_capita + L6.d_ln_gdp_per_capita = 0

* Long Difference Model
reg ld_ln_CO2_emissions_per_capita ld_ln_gdp_per_capita, cluster(countryid)
outreg2 using "$output\ld_co2_gdp_unweighted", se bdec(3) 2aster tex(fragment) replace ctitle("Long Difference Model, LD Natural logarithm of CO2 Emissions per Capita")

reg d_ln_CO2_emissions_per_capita d_ln_gdp_per_capita d_ln_population d_ln_urban_population d_ln_forest_area d_renewable_energy, cluster(countryid)
outreg2 using "$output\ld_co2_gdp_confounders_unweighted", se bdec(3) 2aster tex(fragment) replace ctitle("Long Difference Model, LD Natural logarithm of CO2 Emissions per Capita")

* FE Regressions *
xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita i.year, fe cluster(countryid) 
outreg2 using "$output\fe_co2_gdp_unweighted", se bdec(3) 2aster tex(fragment) label keep(ln_gdp_per_capita) replace

xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy i.year, fe cluster(countryid)
outreg2 using "$output\fe_co2_gdp_confounders_unweighted", se bdec(3) 2aster tex(fragment) keep(ln_gdp_per_capita ln_population ln_urban_population ln_forest_area renewable_energy i.year) replace ctitle("Fixed Effects, Natural logarithm of CO2 Emissions per Capita")

* Cluestered vs Simple Standard Errors 
xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita i.year [w=average_population], fe cluster(countryid)
outreg2 using "$output\fe_co2_gdp_se", se bdec(3) 2aster tex(fragment) keep(ln_gdp_per_capita) replace ctitle("Clustered SE, Natural logarithm of CO2 Emissions per Capita")

xtreg ln_CO2_emissions_per_capita ln_gdp_per_capita i.year [w=average_population], fe 
outreg2 using "$output\fe_co2_gdp_se", se bdec(3) 2aster tex(fragment) keep(ln_gdp_per_capita) append ctitle("Simple SE, Natural logarithm of CO2 Emissions per Capita")

/* Idea of clustered errors: different countries have different unobservable variables that are affecting the CO2 emissions differently */
