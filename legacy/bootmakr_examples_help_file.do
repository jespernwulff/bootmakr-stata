use "https://raw.githubusercontent.com/resonance1/sensemakr-stata/master/darfur.dta", clear

sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
        treat(directlyharmed) benchmark(female)

reg peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, vce(cluster village_factor)

* standard bootstrap
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) benchmark(female) reps(100) dots(10)
 
 * clustered bootstrap
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) benchmark(female) reps(100) dots(10) cluster(village_factor)
 
 * multiple kd values
bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) benchmark(female) reps(10) dots(5) cluster(village_factor) ///
 kd(1 2 3) plot
 
 * grouped benchmark
 bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) gbenchmark(age farmer herder pastv hhsize female) reps(10) dots(5) cluster(village_factor) kd(1 2 3) plot
 
** convergence check
 bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) gbenchmark(age farmer herder pastv hhsize female) reps(10) dots(5) cluster(village_factor) kd(1 2 3) plot 
 
** Inspect bootstrap draws
 bootmakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///
 treat(directlyharmed) gbenchmark(age farmer herder pastv hhsize female) reps(100) dots(5) cluster(village_factor) ///
    converge(minreps(10) stepsize(10) savedata(my_convergence_data))

// After running, you can load and examine the convergence data
use my_convergence_data.dta, clear	

