# bootmakr

Bootstrap inference for `sensemakr` sensitivity analysis in Stata.

## Installation

```stata
net install bootmakr, from("https://raw.githubusercontent.com/jespernwulff/bootmakr-stata/main/")
```

## Quick Start

```stata
* Basic bootstrap sensitivity analysis
sysuse auto, clear
bootmakr price mpg weight, treat(foreign) benchmark(weight) kd(1) reps(500) seed(12345)

* Multiple kd values with plot
bootmakr price mpg weight, treat(foreign) benchmark(weight) kd(1 2 3) reps(500) seed(12345) plot

* Convergence diagnostics
bootmakr price mpg weight, treat(foreign) benchmark(weight) kd(1) reps(2000) seed(12345) converge(minreps(200) stepsize(200))
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

## Directory Structure

```
bootmakr/
├── bootmakr.ado         # Installable program
├── bootmakr.sthlp       # Help file
├── bootmakr.pkg         # Package manifest
├── stata.toc            # Package table of contents
├── bootmakr.do          # Original development script
├── legacy/              # Archived versions (never deleted)
│   └── bootmakr.do
├── CLAUDE.md            # Project rules and session log
└── README.md            # This file
```

## Author

Jesper N. Wulff

Bug reports and feature requests: [GitHub Issues](https://github.com/jespernwulff/bootmakr-stata/issues)
