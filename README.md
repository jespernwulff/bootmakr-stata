# bootmakr

Bootstrap inference for `sensemakr` sensitivity analysis in Stata.

## Installation

```stata
net install bootmakr, from("https://raw.githubusercontent.com/jespernwulff/bootmakr-stata/main/")
```

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

## What bootmakr Does

Wraps Stata's `bootstrap` command around `sensemakr` to produce:
- Percentile bootstrap confidence intervals
- Bootstrap p-values (two-sided, H0: treatment = 0)
- Bootstrap standard errors

## Two Modes

- **Standard mode**: `bootmakr depvar controls, treat(treatvar)` -- builds the `sensemakr` call internally
- **Program mode**: `bootmakr, treat(label) program(my_eclass_program)` -- bootstraps a user-supplied e-class program

## Key Options

- `reps()`, `seed()`, `cluster()`, `strata()` -- bootstrap configuration
- `benchmark()`, `gbenchmark()`, `kd()`, `ky()`, `kr()` -- sensemakr sensitivity parameters
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

With multiple `kd` values: `r(results)` matrix (cols: estimate, se, ci_lower, ci_upper, pvalue).

With `converge()`: additional scalars for SE/p-value CV, range, and means across replication counts.

## Dependencies

- Stata 14.0+
- `sensemakr` (Stata package)

## References

Cinelli, C. and C. Hazlett (2020). "Making sense of sensitivity: Extending omitted variable bias." *Journal of the Royal Statistical Society: Series B (Statistical Methodology)*, 82(1), 39-67.

Cinelli, C., J. Ferwerda, and C. Hazlett (2024). "sensemakr: Sensitivity analysis tools for OLS in R and Stata." *Observational Studies*, 10(2), 93-127. [https://dx.doi.org/10.1353/obs.2024.a946583](https://dx.doi.org/10.1353/obs.2024.a946583).

Lonati, S. and J. N. Wulff (2026). "Why you should not use the ITCV with robust standard errors (and what to do instead)." *SSRN Working Paper*.

## Author

Jesper N. Wulff

Bug reports and feature requests: [GitHub Issues](https://github.com/jespernwulff/bootmakr-stata/issues)
