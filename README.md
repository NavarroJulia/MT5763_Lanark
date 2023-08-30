# MT5763_Lanark
This is a repository for our group coursework.


Tasks done by Julia Navarro: 

# Task 2: Bootstrap (SAS)

• Create a faster equivalent of the bootstrapping macro regBoot.sas. It only needs to work for one
covariate.
• Use the seals data (seals.csv) to perform a regression of testosterone level (in µg/l) on length (in
cm). This is a fictional dataset of male hormone levels in seals of different lengths.
• State and visualise the 95% confidence intervals for the estimates of each parameter (intercept and
slope). Provide a histogram for the distribution of each bootstrapped parameter.
• Compare regBoot.sas to your modified version to determine the speed-up.
• Compare the boostrapped parameter estimates and their 95% confidence intervals to those obtained
using the built-in SAS procedure.


# Task 3: Jackknife (SAS)

Jackknife is another computer intensive method used for variance and bias estimation (it pre-dates the
bootstrap method). It was developed by John Tukey in the 1950s from an idea by Maurice Quenouille. Whilst
in bootstrapping, the observed data (temporarily treated as a “population”), is sampled with replacement
(to simulate the sampling process), in the jackknife method, each sample consists of all but one of the
observations (i.e. sampling without replacement). 

Write and implement code (modifying code already given to you in the lecture notes e.g. the two sample
randomisation test), to obtain a jackknife estimate for the standard error of the mean for seal body length,
using the seals data set (seals.csv).
