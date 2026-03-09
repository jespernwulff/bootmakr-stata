*! version 1.0.0  09mar2026  Jesper N. Wulff
*! bootmakr: Bootstrap inference for sensemakr sensitivity analysis
program define bootmakr, rclass
    version 14.0

    // ----------------------------------------------------------------
    // Two-pass parsing
    // Stata's optional [varlist] consumes all variables in memory when
    // no varlist is typed on the command line, making it impossible to
    // distinguish "no varlist" from "all variables". We first do a
    // lightweight parse to detect program() mode, then re-parse with
    // the correct varlist requirement.
    // ----------------------------------------------------------------

    // Save original command line
    local cmdline `"`0'"'

    // First pass: detect program() and grab anything before the comma
    syntax [anything] [if] [in] [fw aw pw iw], ///
        treat(string) [PROGram(string) *]

    local program_mode = ("`program'" != "")

    // Validate mode
    if `program_mode' & `"`anything'"' != "" {
        display as error "program() and varlist are mutually exclusive"
        exit 198
    }
    if !`program_mode' & `"`anything'"' == "" {
        display as error "varlist required, or use program() option"
        exit 100
    }

    // Second pass: full parse with correct varlist handling
    local 0 `"`cmdline'"'

    if `program_mode' {
        // Program mode: no varlist, treat() is a display label
        syntax [if] [in] [fw aw pw iw], ///
            treat(string) ///
            PROGram(string) ///
            [REPs(integer 1000)] ///
            [seed(integer -1)] ///
            [cluster(varname)] ///
            [idcluster(varname)] ///
            [strata(varname)] ///
            [dots(integer 0)] ///
            [saving(string)] ///
            [boundsindex(numlist min=2 max=2 integer)] ///
            [benchmark(varlist fv ts)] ///
            [gbenchmark(varlist fv ts)] ///
            [kd(numlist >0)] ///
            [ky(numlist >0)] ///
            [kr(numlist >0 <=1)] ///
            [q(real 1)] ///
            [alpha(real 0.05)] ///
            [Level(cilevel)] ///
            [r2dxj_x(numlist >=0 <=1)] ///
            [r2yxj_dx(numlist >=0 <=1)] ///
            [bound_label(string)] ///
            [reduce] ///
            [suppress] ///
            [verbose] ///
            [plot] ///
            [converge(string)]
    }
    else {
        // Standard mode: required varlist with fv/ts expansion
        syntax varlist(min=2 fv ts) [if] [in] [fw aw pw iw], ///
            treat(varname fv ts) ///
            [REPs(integer 1000)] ///
            [seed(integer -1)] ///
            [cluster(varname)] ///
            [idcluster(varname)] ///
            [strata(varname)] ///
            [dots(integer 0)] ///
            [saving(string)] ///
            [boundsindex(numlist min=2 max=2 integer)] ///
            [benchmark(varlist fv ts)] ///
            [gbenchmark(varlist fv ts)] ///
            [kd(numlist >0)] ///
            [ky(numlist >0)] ///
            [kr(numlist >0 <=1)] ///
            [q(real 1)] ///
            [alpha(real 0.05)] ///
            [Level(cilevel)] ///
            [r2dxj_x(numlist >=0 <=1)] ///
            [r2yxj_dx(numlist >=0 <=1)] ///
            [bound_label(string)] ///
            [reduce] ///
            [suppress] ///
            [verbose] ///
            [plot] ///
            [converge(string)]
    }

    // Warn about sensemakr-specific options that are ignored in program() mode
    if `program_mode' {
        local ignored_opts ""
        if "`benchmark'" != "" local ignored_opts "`ignored_opts' benchmark()"
        if "`gbenchmark'" != "" local ignored_opts "`ignored_opts' gbenchmark()"
        if "`r2dxj_x'" != "" local ignored_opts "`ignored_opts' r2dxj_x()"
        if "`r2yxj_dx'" != "" local ignored_opts "`ignored_opts' r2yxj_dx()"
        if "`bound_label'" != "" local ignored_opts "`ignored_opts' bound_label()"
        if "`reduce'" != "" local ignored_opts "`ignored_opts' reduce"
        if "`suppress'" != "" local ignored_opts "`ignored_opts' suppress"
        if `q' != 1 local ignored_opts "`ignored_opts' q()"
        if "`ignored_opts'" != "" {
            display as text "Note: In program() mode, the following options are passed"
            display as text "      to sensemakr by your program, not by bootmakr:`ignored_opts'"
        }
    }

    // Handle level() / alpha() interaction
    // level(cilevel) uses Stata's built-in validation (1-99.99)
    if "`level'" != "" & `alpha' != 0.05 {
        display as error "level() and alpha() are mutually exclusive"
        exit 198
    }
    if "`level'" != "" {
        local alpha = 1 - `level'/100
    }

    // Parse converge suboptions if specified
    local do_converge = 0
    local minreps = 500      // defaults
    local stepsize = 500
    local savedata ""
    local threshold = -1     // flag for not specified

    if "`converge'" != "" {
        local do_converge = 1

        // Parse converge suboptions manually
        while "`converge'" != "" {
            gettoken token converge : converge, parse(" ,")

            if "`token'" == "," {
                continue
            }

            // Check for minreps()
            if regexm("`token'", "^minreps\(([0-9]+)\)$") {
                local minreps = regexs(1)
            }
            // Check for stepsize()
            else if regexm("`token'", "^stepsize\(([0-9]+)\)$") {
                local stepsize = regexs(1)
            }
            // Check for threshold()
            else if regexm("`token'", "^threshold\(([0-9]+)\)$") {
                local threshold = regexs(1)
            }
            // Check for savedata()
            else if regexm("`token'", "^savedata\((.+)\)$") {
                local savedata = regexs(1)
            }
            else if "`token'" != "" {
                display as error "converge(): option `token' not recognized"
                exit 198
            }
        }

        // Set default threshold if not specified (75% of reps)
        if `threshold' == -1 {
            local threshold = round(0.75 * `reps')
        }

        // Validate convergence inputs
        if `minreps' >= `reps' {
            display as error "converge(minreps()) must be less than reps()"
            exit 198
        }
        if `stepsize' <= 0 {
            display as error "converge(stepsize()) must be positive"
            exit 198
        }
        if `threshold' > `reps' {
            display as error "converge(threshold()) must be less than or equal to reps()"
            exit 198
        }
        if `threshold' < `minreps' {
            display as error "converge(threshold()) must be greater than or equal to minreps()"
            exit 198
        }
    }

    // Set default bounds index if not specified
    if "`boundsindex'" == "" {
        local boundsindex "1 5"
    }
    local idx1 : word 1 of `boundsindex'
    local idx2 : word 2 of `boundsindex'

    // Handle ky defaulting to kd (relevant for standard mode and display)
    if "`ky'" == "" & "`kd'" != "" {
        local ky "`kd'"
    }

    // Count number of kd values (controls number of bootstrap expressions)
    local n_kd = 0
    if "`kd'" != "" {
        foreach val in `kd' {
            local ++n_kd
        }
    }
    else {
        local n_kd = 1
    }

    // Note about convergence with multiple kd
    if `do_converge' & `n_kd' > 1 {
        local kd_first : word 1 of `kd'
        display as text "Note: Convergence diagnostics will use first kd value (`kd_first')"
    }

    // Mark sample and weights (standard mode only)
    if !`program_mode' {
        marksample touse
    }
    if "`weight'" != "" {
        local wgt [`weight'`exp']
    }

    // Set seed if provided
    if `seed' > 0 {
        set seed `seed'
    }

    // Build bootstrap expressions for multiple kd values
    local bs_exp ""
    forvalues i = 1/`n_kd' {
        if `i' > 1 {
            local bs_exp "`bs_exp' "
        }
        local bs_exp "`bs_exp'(bound`i': el(e(bounds), `i', `idx2'))"
    }

    // Build bootstrap command - construct options carefully
    local bsopts "reps(`reps') level(`=(1-`alpha')*100')"
    if "`cluster'" != "" {
        local bsopts "`bsopts' cl(`cluster')"
    }
    if "`idcluster'" != "" {
        local bsopts "`bsopts' idcluster(`idcluster')"
    }
    if "`strata'" != "" {
        local bsopts "`bsopts' strata(`strata')"
    }
    if `dots' > 0 {
        local bsopts "`bsopts' dots(`dots')"
    }

    // Suppress default bootstrap output unless verbose option specified
    if "`verbose'" == "" {
        local bsopts "`bsopts' notable noheader"
        if `dots' == 0 {
            local bsopts "`bsopts' nodots"
        }
    }

    // Handle saving option - always save if converge specified
    if `do_converge' {
        if "`saving'" == "" {
            tempfile bsfile
            local bsopts "`bsopts' saving(`bsfile')"
        }
        else {
            local bsopts "`bsopts' saving(`saving', replace)"
            local bsfile "`saving'"
        }
    }
    else {
        if "`saving'" != "" {
            local bsopts "`bsopts' saving(`saving', replace)"
            local bsfile "`saving'"
        }
        else {
            tempfile bsfile
            local bsopts "`bsopts' saving(`bsfile')"
        }
    }

    // Build the command to bootstrap
    if `program_mode' {
        // Program mode: user-supplied eclass program
        local smcmd "`program'"
    }
    else {
        // Standard mode: build sensemakr command
        local smcmd "sensemakr `varlist' if `touse' `wgt', treat(`treat')"

        // Add sensemakr options
        if "`benchmark'" != "" {
            local smcmd "`smcmd' benchmark(`benchmark')"
        }
        if "`gbenchmark'" != "" {
            local smcmd "`smcmd' gbenchmark(`gbenchmark')"
        }
        if "`kd'" != "" {
            local smcmd "`smcmd' kd(`kd')"
        }
        if "`ky'" != "" {
            local smcmd "`smcmd' ky(`ky')"
        }
        if "`kr'" != "" {
            local smcmd "`smcmd' kr(`kr')"
        }
        if `q' != 1 {
            local smcmd "`smcmd' q(`q')"
        }
        if `alpha' != 0.05 {
            local smcmd "`smcmd' alpha(`alpha')"
        }
        if "`r2dxj_x'" != "" {
            local smcmd "`smcmd' r2dxj_x(`r2dxj_x')"
        }
        if "`r2yxj_dx'" != "" {
            local smcmd "`smcmd' r2yxj_dx(`r2yxj_dx')"
        }
        if "`bound_label'" != "" {
            local smcmd "`smcmd' bound_label(`bound_label')"
        }
        if "`reduce'" != "" {
            local smcmd "`smcmd' reduce"
        }
        if "`suppress'" != "" {
            local smcmd "`smcmd' suppress"
        }
    }

    // Run bootstrap
    bootstrap `bs_exp' `wgt', `bsopts': `smcmd'

    // Store bootstrap results
    matrix ci_percentile = e(ci_percentile)
    matrix b_orig = e(b)  // Original point estimate
    local N = e(N)
    local N_reps = e(N_reps)
    local N_misreps = e(N_misreps)
    local N_clust = e(N_clust)  // Number of clusters

    // Compute p-values and SE from bootstrap samples for each kd
    preserve
    quietly use `bsfile', clear

    // Store results for each kd value
    forvalues i = 1/`n_kd' {
        quietly {
            // Use correct variable name (bound1, bound2, etc.)
            keep if !missing(bound`i')

            // Standard error
            summarize bound`i'
            local se_boot`i' = r(sd)
            local mean_boot`i' = r(mean)
            if `i' == 1 {
                local N_successful = r(N)
            }

            // P-value (two-sided)
            count if bound`i' <= 0
            local pL = r(N) / `N_successful'
            count if bound`i' >= 0
            local pR = r(N) / `N_successful'
            local pvalue`i' = 2 * min(`pL', `pR')
        }
        restore, preserve
        quietly use `bsfile', clear
    }
    restore

    // Extract CI bounds for each kd
    forvalues i = 1/`n_kd' {
        local ci_lower`i' = ci_percentile[1, `i']
        local ci_upper`i' = ci_percentile[2, `i']
        local obs_coef`i' = b_orig[1, `i']
    }

    // Get kd values for display
    local kd_list "`kd'"
    if "`kd_list'" == "" {
        local kd_list "."
    }

    // Compute label column width based on longest row label
    local maxlablen = strlen("`treat'")
    if `n_kd' > 1 {
        foreach kd_val in `kd_list' {
            local lablen = strlen("`treat'_`kd_val'")
            if `lablen' > `maxlablen' {
                local maxlablen = `lablen'
            }
        }
    }
    // Minimum width of 13 (matches Stata convention), plus 1 for padding
    local labwidth = max(13, `maxlablen' + 1)
    // Column positions relative to label width
    local c_pipe  = `labwidth' + 1
    local c_coef  = `labwidth' + 5
    local c_se    = `labwidth' + 19
    local c_pval  = `labwidth' + 32
    local c_cil   = `labwidth' + 43
    local c_ciu   = `labwidth' + 55
    local rhs_width = 64
    local total_width = `labwidth' + `rhs_width'

    // Display results in bootstrap-style format
    display _newline as text "Bootstrap results" _col(`=`total_width'-28') "Number of obs" _col(`=`total_width'-10') "=" _col(`=`total_width'-8') as result %9.0fc `N'
    display as text _col(`=`total_width'-28') "Replications" _col(`=`total_width'-10') "=" _col(`=`total_width'-8') as result %9.0fc `N_reps'

    // Add cluster information if clustered with line break
    if "`cluster'" != "" {
        display ""
        display as text _col(`=`c_pipe'+4') "(Replications based on " as result `N_clust' as text " clusters in " as result "`cluster'" as text ")"
    }

    // Add program mode note
    if `program_mode' {
        display as text _col(`=`c_pipe'+4') "(Using user-supplied program: " as result "`program'" as text ")"
    }

    display as text "{hline `labwidth'}{c TT}{hline `rhs_width'}"
    display as text _col(`c_pipe') "{c |}" _col(`=`c_coef'+3') "Observed" _col(`=`c_se'+1') "Bootstrap" _col(`=`c_ciu'+6') "Percentile"
    display as text _col(`c_pipe') "{c |}" _col(`=`c_coef'+4') "Coef." _col(`=`c_se'+1') "Std. Err." _col(`=`c_pval'+1') "P-value" ///
        _col(`=`c_cil'+1') "[" as text %2.0f `=(1-`alpha')*100' "% Conf. Interval]"
    display as text "{hline `labwidth'}{c +}{hline `rhs_width'}"

    // Display results for each kd value
    local kd_counter = 1
    foreach kd_val in `kd_list' {
        // Create row label
        if `n_kd' > 1 {
            local rowlabel "`treat'_`kd_val'"
        }
        else {
            local rowlabel "`treat'"
        }

        display as text "`rowlabel'" _col(`c_pipe') "{c |}" ///
            _col(`c_coef') as result %9.0g `obs_coef`kd_counter'' ///
            _col(`c_se') as result %9.0g `se_boot`kd_counter'' ///
            _col(`=`c_pval'+1') as result %7.4f `pvalue`kd_counter'' ///
            _col(`=`c_cil'+1') as result %9.0g `ci_lower`kd_counter'' ///
            _col(`=`c_ciu'+1') as result %9.0g `ci_upper`kd_counter''

        local ++kd_counter
    }

    display as text "{hline `labwidth'}{c BT}{hline `rhs_width'}"

    // Note about method
    display as text "Note: CI is percentile bootstrap confidence interval"
    display as text "      P-value is bootstrap p-value (H0: " as result "`treat'" as text " = 0)"

    // Add note about benchmark, kd and ky levels (standard mode only)
    if !`program_mode' {
        // Determine which benchmark was used
        local bench_used ""
        if "`gbenchmark'" != "" {
            local bench_used "`gbenchmark'"
        }
        else if "`benchmark'" != "" {
            local bench_used "`benchmark'"
        }

        if "`bench_used'" != "" | "`kd'" != "" | "`ky'" != "" {
            local bench_display = cond("`bench_used'" != "", "`bench_used'", "none")
            local kd_display = cond("`kd'" != "", "`kd'", ".")
            local ky_display = cond("`ky'" != "", "`ky'", ".")
            display as text "      Benchmark: " as result "`bench_display'" ///
                as text ", kd = " as result "`kd_display'" as text ", ky = " as result "`ky_display'"
        }
    }

    // Additional info if there were failed replications
    if `N_misreps' > 0 {
        display as text "Warning: " as result `N_misreps' as text " replications failed"
    }

    // Create plot if requested and multiple kd values
    if "`plot'" != "" & `n_kd' > 1 {
        quietly {
            preserve
            clear
            set obs `n_kd'

            gen kd_val = .
            gen estimate = .
            gen ci_lower = .
            gen ci_upper = .
            gen pvalue = .

            local row = 1
            foreach kd_val in `kd_list' {
                replace kd_val = `kd_val' in `row'
                replace estimate = `obs_coef`row'' in `row'
                replace ci_lower = `ci_lower`row'' in `row'
                replace ci_upper = `ci_upper`row'' in `row'
                replace pvalue = `pvalue`row'' in `row'
                local ++row
            }

            // Get min and max kd values for range
            summarize kd_val
            local kd_min = r(min)
            local kd_max = r(max)
            local kd_range = `kd_max' - `kd_min'
            local plot_min = `kd_min' - 0.05 * `kd_range'
            local plot_max = `kd_max' + 0.05 * `kd_range'
        }

        // Create y-axis title with treatment variable
        local ytitle_text "Adjusted Treatment Effect (`treat')"

        // Create x-axis title with benchmark variable(s)
        local bench_display ""
        if "`gbenchmark'" != "" {
            local bench_display "`gbenchmark'"
        }
        else if "`benchmark'" != "" {
            local bench_display "`benchmark'"
        }

        if "`bench_display'" != "" {
            local xtitle_text "Benchmark strength (`bench_display')"
        }
        else {
            local xtitle_text "Benchmark strength"
        }

        twoway (rspike ci_lower ci_upper kd_val, lcolor(navy) lwidth(medium)) ///
               (scatter estimate kd_val if pvalue < `alpha', msymbol(O) mcolor(navy) msize(large)) ///
               (scatter estimate kd_val if pvalue >= `alpha', msymbol(Oh) mcolor(navy) msize(large)) ///
               (function y=0, range(`plot_min' `plot_max') lcolor(gs8) lpattern(dash) lwidth(thin)), ///
            xtitle("`xtitle_text'") ///
            ytitle("`ytitle_text'") ///
            xlabel(`kd_list') ///
            legend(off) ///
            graphregion(color(white)) bgcolor(white) ///
            note("Note: `=round((1-`alpha')*100)'% confidence intervals based on `N_reps' bootstrap replications." ///
                 "Solid markers: p < `alpha'; hollow markers: p >= `alpha'.", size(vsmall))

        restore
    }
    else if "`plot'" != "" & `n_kd' == 1 {
        display as text "Note: Plot option requires multiple kd values"
    }

    // ========================================================================
    // Convergence diagnostics
    // ========================================================================

    if `do_converge' {
        // Display message before starting convergence analysis
        display _newline as text "Computing convergence statistics" _continue

        preserve
        quietly use `bsfile', clear

        // Keep only successful replications
        quietly keep if !missing(bound1)
        local total_reps = _N

        // Set up storage for convergence results
        tempname conv_results
        tempfile convdata
        postfile `conv_results' reps se pvalue using `convdata'

        // Loop over subsample sizes
        local counter = 0
        forvalues reps_i = `minreps'(`stepsize')`reps' {
            if `reps_i' <= `total_reps' {
                local ++counter

                // Print progress dot for each iteration
                display as text "." _continue

                // Compute SE from first `reps_i' observations
                quietly summarize bound1 in 1/`reps_i'
                local se_conv = r(sd)

                // Compute p-value from first `reps_i' observations
                quietly count if bound1 <= 0 in 1/`reps_i'
                local pL = r(N) / `reps_i'
                quietly count if bound1 >= 0 in 1/`reps_i'
                local pR = r(N) / `reps_i'
                local pval_conv = 2 * min(`pL', `pR')

                // Store results
                post `conv_results' (`reps_i') (`se_conv') (`pval_conv')
            }
        }

        postclose `conv_results'
        display ""  // New line after progress dots

        // Create histogram of bootstrap distribution before leaving this dataset
        quietly summarize bound1, detail
        local p50 = r(p50)
        local boot_mean = r(mean)
        local boot_sd = r(sd)

        // Create histogram
        twoway (histogram bound1, freq color(navy%30) lcolor(navy)), ///
            xline(`obs_coef1', lcolor(black) lwidth(medium) lpattern(dash)) ///
            ytitle("") ///
            ylabel(none) ///
            xtitle("") ///
            legend(off) ///
            graphregion(color(white)) bgcolor(white) ///
            name(boot_hist, replace)

        restore

        // Load convergence results
        preserve
        quietly use `convdata', clear

        // Create convergence plots
        graph twoway ///
            (scatter se reps, mcolor(navy) msize(medium)) ///
            (line se reps, lcolor(navy) lpattern(dash) lwidth(medium)), ///
            ytitle("Standard Error") ///
            xtitle("") ///
            legend(off) ///
            graphregion(color(white)) bgcolor(white) ///
            name(se_conv, replace)

        graph twoway ///
            (scatter pvalue reps, mcolor(maroon) msize(medium)) ///
            (line pvalue reps, lcolor(maroon) lpattern(dash) lwidth(medium)), ///
            xtitle("Number of Bootstrap Replications") ///
            ytitle("Two-sided P-value") ///
            legend(off) ///
            graphregion(color(white)) bgcolor(white) ///
            name(pval_conv, replace)

        // Combine all three figures
        graph combine boot_hist se_conv pval_conv, ///
            rows(3) ///
            graphregion(color(white)) ///
            name(convergence_combined, replace)

        // Compute convergence statistics
        quietly {
            // Overall statistics
            summarize se
            local se_mean = r(mean)
            local se_range = r(max) - r(min)
            local se_cv = (r(sd) / r(mean)) * 100

            summarize pvalue
            local p_mean = r(mean)
            local p_range = r(max) - r(min)
            local p_cv = (r(sd) / r(mean)) * 100

            // Statistics for upper threshold - use threshold directly now
            summarize se if reps >= `threshold'
            local se_range_high = r(max) - r(min)
            local se_cv_high = (r(sd) / r(mean)) * 100

            summarize pvalue if reps >= `threshold'
            local p_range_high = r(max) - r(min)
            local p_cv_high = (r(sd) / r(mean)) * 100
        }

        // Display Stata-style summary table with narrow columns
        display as text "{hline 78}"
        display as text "Bootstrap convergence diagnostics"
        display as text "Reps: `minreps'(`stepsize')`reps'"
        display as text "{hline 78}"
        display as text "Summary across replication counts"
        display as text _col(15) "{c |}" _col(20) "Mean" _col(30) "Range" _col(42) "CV%" ///
            _col(52) "Range" _col(64) "CV%"
        display as text _col(15) "{c |}" _col(20) "(all)" _col(30) "(all)" _col(41) "(all)" ///
            _col(51) "(>=`threshold')" _col(62) "(>=`threshold')"
        display as text "{hline 14}{c +}{hline 63}"

        // Standard error row
        display as text "Std. error" _col(15) "{c |}" ///
            _col(18) as result %8.4f `se_mean' ///
            _col(28) as result %8.4f `se_range' ///
            _col(40) as result %6.2f `se_cv' ///
            _col(50) as result %8.4f `se_range_high' ///
            _col(62) as result %6.2f `se_cv_high'

        // P-value row
        display as text "P-value" _col(15) "{c |}" ///
            _col(18) as result %8.4f `p_mean' ///
            _col(28) as result %8.4f `p_range' ///
            _col(40) as result %6.2f `p_cv' ///
            _col(50) as result %8.4f `p_range_high' ///
            _col(62) as result %6.2f `p_cv_high'

        display as text "{hline 78}"
        display as text "Note: CV% = Coefficient of variation (standard deviation / mean x 100)"
        display as text "      (all) = statistics across all replication counts"
        display as text "      (>=`threshold') = statistics for replication counts >= `threshold'"

        // Save convergence data if requested
        if "`savedata'" != "" {
            quietly save "`savedata'", replace
            display as text _newline "Convergence data saved to: `savedata'.dta"
        }

        restore

        // Add convergence statistics to return
        return scalar conv_se_mean = `se_mean'
        return scalar conv_se_range = `se_range'
        return scalar conv_se_cv = `se_cv'
        return scalar conv_se_range_high = `se_range_high'
        return scalar conv_se_cv_high = `se_cv_high'
        return scalar conv_p_mean = `p_mean'
        return scalar conv_p_range = `p_range'
        return scalar conv_p_cv = `p_cv'
        return scalar conv_p_range_high = `p_range_high'
        return scalar conv_p_cv_high = `p_cv_high'
        return scalar conv_thresh_reps = `threshold'
        return scalar boot_mean = `boot_mean'
        return scalar boot_sd = `boot_sd'
    }

    // Return results (for first kd value, or create matrices for all)
    return clear
    return scalar N = `N'
    return scalar N_reps = `N_reps'
    return scalar N_successful = `N_successful'
    if "`cluster'" != "" {
        return scalar N_clust = `N_clust'
    }

    // Return scalars for first kd value
    return scalar estimate = `obs_coef1'
    return scalar se = `se_boot1'
    return scalar ci_lower = `ci_lower1'
    return scalar ci_upper = `ci_upper1'
    return scalar p = `pvalue1'

    // Return matrix with all results if multiple kd
    if `n_kd' > 1 {
        tempname results
        matrix `results' = J(`n_kd', 5, .)
        matrix colnames `results' = estimate se ci_lower ci_upper pvalue

        local row_counter = 1
        foreach kd_val in `kd_list' {
            matrix `results'[`row_counter', 1] = `obs_coef`row_counter''
            matrix `results'[`row_counter', 2] = `se_boot`row_counter''
            matrix `results'[`row_counter', 3] = `ci_lower`row_counter''
            matrix `results'[`row_counter', 4] = `ci_upper`row_counter''
            matrix `results'[`row_counter', 5] = `pvalue`row_counter''
            local ++row_counter
        }

        return matrix results = `results'
    }

    // Add convergence statistics to return if ran (only add if converge was run)
    if `do_converge' {
        return scalar conv_se_mean = `se_mean'
        return scalar conv_se_range = `se_range'
        return scalar conv_se_cv = `se_cv'
        return scalar conv_se_range_high = `se_range_high'
        return scalar conv_se_cv_high = `se_cv_high'
        return scalar conv_p_mean = `p_mean'
        return scalar conv_p_range = `p_range'
        return scalar conv_p_cv = `p_cv'
        return scalar conv_p_range_high = `p_range_high'
        return scalar conv_p_cv_high = `p_cv_high'
        return scalar conv_thresh_reps = `threshold'
        return scalar boot_mean = `boot_mean'
        return scalar boot_sd = `boot_sd'
    }

    // Return matrix
    return matrix ci_percentile = ci_percentile
end
