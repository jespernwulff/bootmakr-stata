# bootmakr

Bootstrap inference for `sensemakr` sensitivity analysis in Stata.

**Documentation, a getting-started guide, a worked example and the argument
behind the command: <https://jespernwulff.github.io/bootmakr/>**

The R package of the same name is at
<https://github.com/jespernwulff/bootmakr>.

## Installation

```stata
ssc install sensemakr
net install bootmakr, from("https://raw.githubusercontent.com/jespernwulff/bootmakr-stata/main/")
```

To update an existing installation, add the `replace` option. The example
data set `firms.dta` is an ancillary file: `net get bootmakr, from(...)`
copies it into the current folder.

## Why bootstrap?

The impact threshold of a confounding variable (ITCV) is read as the product
of correlations an omitted variable needs to overturn a result. Lonati and
Wulff (2026) show that this reading breaks down when the regression is
estimated with heteroskedasticity- or cluster-robust standard errors, and
that the analytic confidence interval of `sensemakr` breaks down for the
same reason. The remedy is the bootstrap that Cinelli, Ferwerda and Hazlett
(2024, Appendix C) propose: resample the data the way you would choose
standard errors, rerun `sensemakr` and keep the bias-adjusted estimate in
every replication. `bootmakr` automates it, and reports how strong the
assumed omitted variable is on the scale of the ITCV. See
[Why bootstrap?](https://jespernwulff.github.io/bootmakr/articles/why-bootstrap.html)

## Quick Start

`firms.dta` is a simulated panel of 250 firms observed for 20 years. The
true effect of `x` on `y` is 0.25. An unobserved firm-level variable `q`, as
strong as the observed control `c`, biases the regression that omits it, and
the within-firm components of `x` and of the disturbance are persistent, so
standard errors must be clustered by firm.

```stata
net get bootmakr, from("https://raw.githubusercontent.com/jespernwulff/bootmakr-stata/main/")
use firms, clear

* An omitted variable as strong as c (kd(1), the default); firms resampled
bootmakr y x c, treat(x) benchmark(c) cluster(firm) seed(123)

* Several strengths at once, with the plot
bootmakr y x c, treat(x) benchmark(c) kd(0.5 1 1.5 2) cluster(firm) seed(123) plot

* Observations rather than firms resampled (heteroskedasticity only)
bootmakr y x c, treat(x) benchmark(c) seed(123)

* Convergence diagnostics
bootmakr y x c, treat(x) benchmark(c) cluster(firm) reps(5000) seed(123) ///
    converge(minreps(500) stepsize(500))

* Because the data are simulated, the answer can be checked
regress y x c q, vce(cluster firm)
```

For full documentation, type `help bootmakr` in Stata after installation.

## What bootmakr Does

Wraps Stata's `bootstrap` command around `sensemakr` to produce:
- Percentile bootstrap confidence intervals
- Bootstrap p-values (two-sided, H0: treatment = 0)
- Bootstrap standard errors
- A descriptive *benchmark strength* block: the partial R-squared of the
  benchmark with treatment and outcome, the strength of the omitted variable
  this implies at each `kd()`, and its *impact*, the product of its partial
  correlations with the outcome and with the treatment on the scale of the
  ITCV

## Two Modes

- **Standard mode**: `bootmakr depvar controls, treat(treatvar)` -- builds the `sensemakr` call internally
- **Program mode**: `bootmakr, treat(label) program(my_eclass_program)` -- bootstraps a user-supplied e-class program

## Key Options

- `reps()`, `seed()`, `cluster()`, `strata()` -- bootstrap configuration
- `benchmark()`, `gbenchmark()`, `kd()`, `ky()` -- sensitivity parameters; `kd()` defaults to 1, an omitted variable exactly as strong as the benchmark
- `alpha()` / `level()` -- significance level
- `plot` -- coefficient plot across multiple `kd` values
- `converge()` -- convergence diagnostics with suboptions: `minreps()`, `stepsize()`, `threshold()`, `savedata()`
- `saving()` -- save bootstrap replication dataset

## Returned Results (r-class)

| Scalar | Description |
|--------|-------------|
| `r(estimate)` | Point estimate (first kd) |
| `r(se)` | Bootstrap standard error |
| `r(ci_lower)`, `r(ci_upper)` | Percentile CI bounds |
| `r(p)` | Bootstrap p-value |
| `r(N)`, `r(N_reps)`, `r(N_successful)` | Sample size, replications requested, replications in which every bound was computed |
| `r(N_clust)` | Number of clusters (if clustered) |
| `r(r2dxj_x)`, `r(r2yxj_dx)` | Partial R-squared of the benchmark with treatment and outcome |
| `r(r2dz_x)`, `r(r2yz_dx)` | Implied partial R-squared of the omitted variable (first kd) |
| `r(impact)` | Impact of the omitted variable on the ITCV scale (first kd) |
| `r(r_yd_x)` | Partial correlation of the outcome with the treatment given the covariates |

With multiple `kd` values: `r(results)` matrix (cols: estimate, se, ci_lower,
ci_upper, pvalue, N_ok). Each p-value uses that kd's own number of
successful replications, `N_ok`, as denominator.

`r(benchmark_strength)` matrix, one row per `kd` (cols: kd, ky, r2dz_x,
r2yz_dx, r_dz_x, r_yz_dx, r_yz_x, impact).

With `converge()`: additional scalars for SE/p-value CV, range, and means across replication counts.

## Dependencies

- Stata 14.0+
- `sensemakr` (Stata package, `ssc install sensemakr`)

`kr()`, `r2dxj_x()`, `r2yxj_dx()`, `bound_label()` and `reduce` are passed on to
`sensemakr` unchanged. The version of `sensemakr` on SSC (28 April 2020) does
not accept them; see `help bootmakr`.

## References

Cinelli, C. and C. Hazlett (2020). "Making sense of sensitivity: Extending omitted variable bias." *Journal of the Royal Statistical Society: Series B (Statistical Methodology)*, 82(1), 39-67. [https://doi.org/10.1111/rssb.12348](https://doi.org/10.1111/rssb.12348)

Cinelli, C., J. Ferwerda, and C. Hazlett (2024). "sensemakr: Sensitivity analysis tools for OLS in R and Stata." *Observational Studies*, 10(2), 93-127. [https://doi.org/10.1353/obs.2024.a946583](https://doi.org/10.1353/obs.2024.a946583)

Lonati, S. and J. N. Wulff (2026). "Why you should not use the ITCV with robust standard errors (and what to do instead)." *Academy of Management Proceedings*, 2026(1). [https://doi.org/10.5465/AMPROC.2026.247bp](https://doi.org/10.5465/AMPROC.2026.247bp)

## Authors

Jesper N. Wulff and Sirio Lonati

Bug reports and feature requests: [GitHub Issues](https://github.com/jespernwulff/bootmakr-stata/issues)
