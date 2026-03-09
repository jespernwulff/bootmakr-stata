{smcl}
{* *! version 1.0.0  09mar2026}{...}
{viewerjumpto "Syntax" "bootmakr##syntax"}{...}
{viewerjumpto "Description" "bootmakr##description"}{...}
{viewerjumpto "Options" "bootmakr##options"}{...}
{viewerjumpto "Stored results" "bootmakr##results"}{...}
{viewerjumpto "Examples" "bootmakr##examples"}{...}
{viewerjumpto "Author" "bootmakr##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:bootmakr} {hline 2}}Bootstrap inference for sensemakr sensitivity analysis{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Standard mode

{p 8 16 2}
{cmd:bootmakr} {varlist} {ifin} {weight}{cmd:,}
{opth treat(varname)}
[{it:options}]

{pstd}
Program mode

{p 8 16 2}
{cmd:bootmakr} {ifin} {weight}{cmd:,}
{opt treat(string)}
{opt program(string)}
[{it:options}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth treat(varname)}}treatment variable (standard mode) or label (program mode){p_end}

{syntab:Mode}
{synopt:{opt program(string)}}user-supplied e-class program to bootstrap instead of {cmd:sensemakr}{p_end}

{syntab:Bootstrap}
{synopt:{opt reps(#)}}number of bootstrap replications; default is {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opth cluster(varname)}}variable identifying resampling clusters{p_end}
{synopt:{opth idcluster(varname)}}variable for new cluster IDs in bootstrap samples{p_end}
{synopt:{opth strata(varname)}}variable identifying strata{p_end}
{synopt:{opt dots(#)}}display a dot every {it:#} replications; {cmd:0} = no dots{p_end}
{synopt:{opt saving(filename)}}save bootstrap replications to {it:filename}{p_end}
{synopt:{opt verbose}}display default {cmd:bootstrap} header and table{p_end}

{syntab:Sensitivity (standard mode)}
{synopt:{opth benchmark(varlist)}}benchmark covariate(s) for bound calculation{p_end}
{synopt:{opth gbenchmark(varlist)}}group benchmark covariate(s){p_end}
{synopt:{opt kd(numlist)}}multiplier(s) for benchmark strength on treatment; accepts multiple values{p_end}
{synopt:{opt ky(numlist)}}multiplier(s) for benchmark strength on outcome; defaults to {cmd:kd}{p_end}
{synopt:{opt kr(numlist)}}relative strength parameter(s); values in (0, 1]{p_end}
{synopt:{opt q(#)}}percentage of treatment effect to explain; default is {cmd:q(1)}{p_end}
{synopt:{opth r2dxj_x(numlist)}}partial R-squared of confounder with treatment{p_end}
{synopt:{opth r2yxj_dx(numlist)}}partial R-squared of confounder with outcome{p_end}
{synopt:{opt bound_label(string)}}custom label for the bounds{p_end}
{synopt:{opt reduce}}use reduce formula for bound{p_end}
{synopt:{opt suppress}}suppress {cmd:sensemakr} output{p_end}
{synopt:{opt boundsindex(# #)}}row and column indices for {cmd:e(bounds)}; default is {cmd:1 5}{p_end}

{syntab:Significance}
{synopt:{opt alpha(#)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synopt:{opt level(#)}}confidence level; default is {cmd:level(95)}{p_end}

{syntab:Display}
{synopt:{opt plot}}plot estimates and CIs across {cmd:kd} values (requires multiple {cmd:kd}){p_end}

{syntab:Convergence}
{synopt:{opt converge(string)}}run convergence diagnostics with suboptions{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:fweight}s, {cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed;
see {help weight}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:bootmakr} performs bootstrap inference for {cmd:sensemakr} sensitivity
analysis. It wraps Stata's {cmd:bootstrap} command around {cmd:sensemakr} to
produce percentile bootstrap confidence intervals, bootstrap p-values, and
bootstrap standard errors for bias-adjusted treatment effects.

{pstd}
In {bf:standard mode}, you supply a {varlist} (dependent variable and
controls) and {opt treat()} specifying the treatment variable. {cmd:bootmakr}
constructs and bootstraps the {cmd:sensemakr} call internally.

{pstd}
In {bf:program mode}, you supply a user-written e-class program via
{opt program()} that itself calls {cmd:sensemakr} (or any command that stores
results in {cmd:e(bounds)}). {opt treat()} is used only as a display label.
This mode is useful when you need to control the estimation before
{cmd:sensemakr}, e.g., running a specific regression first.

{pstd}
When multiple {cmd:kd} values are specified, {cmd:bootmakr} bootstraps each
bound separately and reports results for each. The {opt plot} option
produces a coefficient plot across {cmd:kd} values.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth treat(varname)} specifies the treatment variable in standard mode.
In program mode, {opt treat(string)} is a label used in the output table.

{dlgtab:Mode}

{phang}
{opt program(string)} specifies a user-written program that posts
results to {cmd:e(bounds)}. When this option is specified, {cmd:bootmakr}
enters program mode and does not accept a {varlist}. Sensitivity options
({cmd:benchmark}, {cmd:kd}, etc.) are not passed by {cmd:bootmakr} in this
mode; your program is responsible for including them.

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} specifies the number of bootstrap replications. The default
is 1000.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility.

{phang}
{opth cluster(varname)} specifies a variable identifying clusters for
cluster bootstrap resampling.

{phang}
{opth idcluster(varname)} creates a new variable containing unique
cluster identifiers in the bootstrap samples.

{phang}
{opth strata(varname)} specifies a variable identifying strata for
stratified bootstrap resampling.

{phang}
{opt dots(#)} requests that a dot be displayed every {it:#} replications
to show progress. The default is {cmd:0} (no dots).

{phang}
{opt saving(filename)} saves the bootstrap replications to {it:filename}.

{phang}
{opt verbose} displays the default {cmd:bootstrap} header and coefficient
table. By default, {cmd:bootmakr} suppresses the standard {cmd:bootstrap}
output and displays its own formatted table.

{dlgtab:Sensitivity (standard mode)}

{phang}
{opth benchmark(varlist)} specifies one or more benchmark covariates
for calculating sensitivity bounds.

{phang}
{opth gbenchmark(varlist)} specifies one or more group benchmark
covariates.

{phang}
{opt kd(numlist)} specifies one or more multipliers for benchmark
strength on treatment. When multiple values are given (e.g.,
{cmd:kd(1 2 3)}), {cmd:bootmakr} bootstraps each bound separately.

{phang}
{opt ky(numlist)} specifies multipliers for benchmark strength on
outcome. If omitted, defaults to the value(s) of {cmd:kd}.

{phang}
{opt kr(numlist)} specifies relative strength parameter(s); values
must be in (0, 1].

{phang}
{opt q(#)} specifies the fraction of the treatment effect to be explained
by the confounder. The default is {cmd:q(1)}.

{phang}
{opth r2dxj_x(numlist)} specifies the hypothesized partial R-squared of
the confounder with the treatment.

{phang}
{opth r2yxj_dx(numlist)} specifies the hypothesized partial R-squared of
the confounder with the outcome.

{phang}
{opt bound_label(string)} specifies a custom label for the bounds in
{cmd:sensemakr} output.

{phang}
{opt reduce} uses the reduce formula for bound calculation.

{phang}
{opt suppress} suppresses {cmd:sensemakr} output during each replication.

{phang}
{opt boundsindex(# #)} specifies the row and column indices used to
extract the bound from {cmd:e(bounds)}. The default is {cmd:1 5}.

{dlgtab:Significance}

{phang}
{opt alpha(#)} specifies the significance level. The default is 0.05.
This option is mutually exclusive with {opt level()}.

{phang}
{opt level(#)} specifies the confidence level as a percentage (e.g., 95).
This option is mutually exclusive with {opt alpha()}.

{dlgtab:Display}

{phang}
{opt plot} produces a coefficient plot showing the point estimates and
bootstrap confidence intervals across {cmd:kd} values. Requires that
multiple {cmd:kd} values are specified. Solid markers indicate
p < alpha; hollow markers indicate p >= alpha.

{dlgtab:Convergence}

{phang}
{opt converge(string)} runs convergence diagnostics to assess whether the
number of bootstrap replications is sufficient. Produces three combined
graphs: a histogram of the bootstrap distribution, and plots of the
standard error and p-value as functions of the number of replications.
Also displays a summary table with coefficient of variation statistics.

{pmore}
Suboptions of {opt converge()}:

{phang2}
{opt minreps(#)} specifies the minimum number of replications to start
the convergence assessment. The default is 500.

{phang2}
{opt stepsize(#)} specifies the increment between evaluation points.
The default is 500.

{phang2}
{opt threshold(#)} specifies the replication count above which "high"
convergence statistics are reported. The default is 75% of {cmd:reps()}.

{phang2}
{opt savedata(filename)} saves the convergence data to {it:filename}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:bootmakr} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(N_reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:r(N_successful)}}number of successful replications{p_end}
{synopt:{cmd:r(N_clust)}}number of clusters (if {cmd:cluster()} specified){p_end}
{synopt:{cmd:r(estimate)}}point estimate (first {cmd:kd} value){p_end}
{synopt:{cmd:r(se)}}bootstrap standard error{p_end}
{synopt:{cmd:r(ci_lower)}}lower bound of percentile CI{p_end}
{synopt:{cmd:r(ci_upper)}}upper bound of percentile CI{p_end}
{synopt:{cmd:r(p)}}bootstrap p-value (two-sided){p_end}

{p2col 5 25 29 2: Scalars (convergence, if {cmd:converge()} specified)}{p_end}
{synopt:{cmd:r(conv_se_mean)}}mean SE across replication counts{p_end}
{synopt:{cmd:r(conv_se_range)}}range of SE across all replication counts{p_end}
{synopt:{cmd:r(conv_se_cv)}}CV% of SE across all replication counts{p_end}
{synopt:{cmd:r(conv_se_range_high)}}range of SE above threshold{p_end}
{synopt:{cmd:r(conv_se_cv_high)}}CV% of SE above threshold{p_end}
{synopt:{cmd:r(conv_p_mean)}}mean p-value across replication counts{p_end}
{synopt:{cmd:r(conv_p_range)}}range of p-value across all replication counts{p_end}
{synopt:{cmd:r(conv_p_cv)}}CV% of p-value across all replication counts{p_end}
{synopt:{cmd:r(conv_p_range_high)}}range of p-value above threshold{p_end}
{synopt:{cmd:r(conv_p_cv_high)}}CV% of p-value above threshold{p_end}
{synopt:{cmd:r(conv_thresh_reps)}}threshold replication count{p_end}
{synopt:{cmd:r(boot_mean)}}mean of bootstrap distribution{p_end}
{synopt:{cmd:r(boot_sd)}}standard deviation of bootstrap distribution{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(ci_percentile)}}percentile CI bounds (2 x {it:k} matrix){p_end}
{synopt:{cmd:r(results)}}results matrix with columns: estimate, se, ci_lower, ci_upper, pvalue (if multiple {cmd:kd} values){p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}
These examples use the Darfur data from Hazlett (2020), available at:{p_end}
{phang2}{cmd:. use "https://raw.githubusercontent.com/resonance1/sensemakr-stata/master/darfur.dta", clear}{p_end}

{pstd}Standard bootstrap with benchmark{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed) benchmark(female) reps(500) seed(12345)}{p_end}

{pstd}Clustered bootstrap{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed) benchmark(female) reps(500) seed(12345)}{p_end}
{phang2}{cmd:     cluster(village_factor)}{p_end}

{pstd}Multiple kd values with plot{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed) benchmark(female) kd(1 2 3)}{p_end}
{phang2}{cmd:     reps(500) seed(12345) cluster(village_factor) plot}{p_end}

{pstd}Group benchmark{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed)}{p_end}
{phang2}{cmd:     gbenchmark(age farmer herder pastv hhsize female)}{p_end}
{phang2}{cmd:     reps(500) seed(12345) cluster(village_factor) kd(1 2 3) plot}{p_end}

{pstd}Convergence diagnostics{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed)}{p_end}
{phang2}{cmd:     gbenchmark(age farmer herder pastv hhsize female)}{p_end}
{phang2}{cmd:     reps(1000) seed(12345) cluster(village_factor)}{p_end}
{phang2}{cmd:     converge(minreps(100) stepsize(100))}{p_end}

{pstd}Saving and inspecting bootstrap draws{p_end}
{phang2}{cmd:. bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f,}{p_end}
{phang2}{cmd:     treat(directlyharmed)}{p_end}
{phang2}{cmd:     gbenchmark(age farmer herder pastv hhsize female)}{p_end}
{phang2}{cmd:     reps(500) seed(12345) cluster(village_factor)}{p_end}
{phang2}{cmd:     converge(minreps(100) stepsize(100) savedata(my_convergence_data))}{p_end}
{phang2}{cmd:. use my_convergence_data.dta, clear}{p_end}


{marker references}{...}
{title:References}

{phang}
Cinelli, C. and C. Hazlett. 2020.
Making sense of sensitivity: Extending omitted variable bias.
{it:Journal of the Royal Statistical Society: Series B (Statistical Methodology)} 82(1): 39-67.
{p_end}

{phang}
Cinelli, C., J. Ferwerda, and C. Hazlett. 2024.
sensemakr: Sensitivity analysis tools for OLS in R and Stata.
{it:Observational Studies} 10(2): 93-127.
{browse "https://dx.doi.org/10.1353/obs.2024.a946583"}
{p_end}

{phang}
Lonati, S. and J. N. Wulff. 2026.
Why you should not use the ITCV with robust standard errors (and what to do instead).
{it:SSRN Working Paper}.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Jesper N. Wulff{p_end}

{pstd}
Bug reports and feature requests:{p_end}
{pstd}
{browse "https://github.com/jespernwulff/bootmakr-stata/issues"}
{p_end}
