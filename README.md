# bootmakr

Bootstrap inference for `sensemakr` sensitivity analysis in Stata.

**Documentation, a getting-started guide and a worked example:
<https://jespernwulff.github.io/bootmakr/>**

The R package of the same name is at
<https://github.com/jespernwulff/bootmakr>.

## Installation

```stata
ssc install sensemakr
net install bootmakr, from("https://raw.githubusercontent.com/jespernwulff/bootmakr-stata/main/")
```

To update an existing installation, add the `replace` option.

## Quick Start

```stata
* Load Darfur data (Hazlett 2020)
use "https://raw.githubusercontent.com/resonance1/sensemakr-stata/master/darfur.dta", clear

* Standard bootstrap with benchmark
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
    treat(directlyharmed) benchmark(female) reps(500) seed(12345)

* Clustered bootstrap
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
    treat(directlyharmed) benchmark(female) reps(500) seed(12345) ///
    cluster(village_factor)

* Multiple kd values with plot
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
    treat(directlyharmed) benchmark(female) kd(1 2 3) ///
    reps(500) seed(12345) cluster(village_factor) plot

* Convergence diagnostics
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
    treat(directlyharmed) gbenchmark(age farmer herder pastv hhsize female) ///
    reps(1000) seed(12345) cluster(village_factor) ///
    converge(minreps(100) stepsize(100))
```

For full documentation, type `help bootmakr` in Stata after installation.

These examples include an indicator for each of 486 villages, which Stata
re-estimates in every replication (about a second each). The
[getting-started guide](https://jespernwulff.github.io/bootmakr/articles/stata.html)
uses an example that runs in under a minute.

## What bootmakr Does

Wraps Stata's `bootstrap` command around `sensemakr` to produce:
- Percentile bootstrap confidence intervals
- Bootstrap p-values (two-sided, H0: treatment = 0)
- Bootstrap standard errors
- A descriptive *benchmark strength* block: the partial R-squared of the
  benchmark with treatment and outcome, the strength of the omitted variable
  this implies at each `kd()`, and the corresponding partial correlations

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
| `r(N)`, `r(N_reps)`, `r(N_successful)` | Sample and replication counts |
| `r(N_clust)` | Number of clusters (if clustered) |

| `r(r2dxj_x)`, `r(r2yxj_dx)` | Partial R-squared of the benchmark with treatment and outcome |
| `r(r2dz_x)`, `r(r2yz_dx)` | Implied partial R-squared of the omitted variable (first kd) |

With multiple `kd` values: `r(results)` matrix (cols: estimate, se, ci_lower, ci_upper, pvalue).

`r(benchmark_strength)` matrix, one row per `kd` (cols: kd, ky, r2dz_x, r2yz_dx, r_dz_x, r_yz_dx).

With `converge()`: additional scalars for SE/p-value CV, range, and means across replication counts.

## Dependencies

- Stata 14.0+
- `sensemakr` (Stata package, `ssc install sensemakr`)

`kr()`, `r2dxj_x()`, `r2yxj_dx()`, `bound_label()` and `reduce` are passed on to
`sensemakr` unchanged. The version of `sensemakr` on SSC (28 April 2020) does
not accept them; see `help bootmakr`.

## References

Cinelli, C. and C. Hazlett (2020). "Making sense of sensitivity: Extending omitted variable bias." *Journal of the Royal Statistical Society: Series B (Statistical Methodology)*, 82(1), 39-67.

Cinelli, C., J. Ferwerda, and C. Hazlett (2024). "sensemakr: Sensitivity analysis tools for OLS in R and Stata." *Observational Studies*, 10(2), 93-127. [https://dx.doi.org/10.1353/obs.2024.a946583](https://dx.doi.org/10.1353/obs.2024.a946583).

Lonati, S. and J. N. Wulff (2026). "Why you should not use the ITCV with robust standard errors (and what to do instead)." *SSRN Working Paper*.

## Authors

Jesper N. Wulff and Sirio Lonati

Bug reports and feature requests: [GitHub Issues](https://github.com/jespernwulff/bootmakr-stata/issues)
