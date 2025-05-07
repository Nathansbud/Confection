#lang forge/temporal

open "confection-core.frg"

option run_sterling "con-visualizer.js"
option max_tracelength 26
// option solver Glucose
// option bitwidth 3

-- partial instance to define sequence of time stamps. 
-- next relation ensures theres a loop the sequence to work with temporal forge
-- optimizes with the solver for fast trace times
inst Timeline25 {
  Timestamp = `T0 + `T1 + `T2 + `T3 + `T4 + `T5 + `T6 + `T7 +
    `T8 + `T9 + `T10 + `T11 + `T12 + `T13 + `T14 + `T15 +
    `T16 + `T17 + `T18 + `T19 + `T20 + `T21 + `T22 + `T23 +
    `T24 + `Unreachable

    next = `T0 -> `T1  + `T1  -> `T2  + `T2  -> `T3  + `T3  -> `T4 +
    `T4 -> `T5  + `T5  -> `T6  + `T6  -> `T7  + `T7  -> `T8 +
    `T8 -> `T9  + `T9  -> `T10 + `T10 -> `T11 + `T11 -> `T12 +
    `T12 -> `T13 + `T13 -> `T14 + `T14 -> `T15 + `T15 -> `T16 +
    `T16 -> `T17 + `T17 -> `T18 + `T18 -> `T19 + `T19 -> `T20 +
    `T20 -> `T21 + `T21 -> `T22 + `T22 -> `T23 + `T23 -> `T24 +
    `T24 -> `T0 + `Unreachable -> `Unreachable
    
    // // Limit ints to -4 thru 3 (bit-width 8)
    #Int = 3
}

inst Timeline8 {
  Timestamp = `T0 + `T1 + `T2 + `T3 + `T4 + `T5 + `T6 + `T7 + `Unreachable

    next = `T0 -> `T1  + `T1  -> `T2  + `T2  -> `T3  + `T3  -> `T4 +
    `T4 -> `T5  + `T5  -> `T6  + `T6  -> `T7  + `T7  -> `T0 + `Unreachable -> `Unreachable
    
    // // Limit ints to -4 thru 3 (bit-width 8)
    #Int = 3
}

-- stable seed, population recovers fully within 8 steps
pred zigSeed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1 + 
        0 -> 2

    no Configuration.sRecovered
    Configuration.sCutoff = `T7
}

-- stable seed, population recovers
pred diag2Seed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T7
}

-- stable seed, population recovers
pred bowSeed {
    Configuration.sInfected = 
        0 -> -1 + 0 -> 3 + 
        2 -> 1
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T15
}

-- doesn't recover within 25 steps, cool pattern though
pred nabowSeed {
    Configuration.sInfected =
        -1 -> -1 + -1 -> 3 + 
        0 -> 1
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T24
}

-- creates an "immunity shield", but due to toroidal BC infection propagates, making all infected
pred cubeSeed { 
    Configuration.sInfected = 
        0 -> 0 + 
        0 -> 1 +
        1 -> 0

    no Configuration.sRecovered
    Configuration.sCutoff = `T24
}

-- original glider from GoL, now spreads to a fully infected population
pred gliderSeed {
    Configuration.sInfected = 
        0 -> 1 +
        1 -> 2 + 
        2 -> 0 + 2 -> 1 + 2 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T24

}

pred workingGliderSmallSeed {
    Configuration.sInfected = -1 -> -1 + 0 -> -1 + 1 -> 0 + -2 -> 0
    Configuration.sRecovered = -1 -> 0 + 0 -> 0 + 1 -> 1+ -2 -> 1
    Configuration.sCutoff = `T24
}

pred workingGliderBigSeed {
    Configuration.sInfected = -1 -> -1 + 0 -> -1 + 1 -> 0 + -2 -> 0 + 2 -> 0 + -3 -> 0 + 3 -> 1 + -4 -> 1
    Configuration.sRecovered = -1 -> 0 + 0 -> 0 + 1 -> 1+ -2 -> 1 + 2 -> 1 + -3 -> 1 + 3 -> 2 + -4 -> 2
    Configuration.sCutoff = `T24
}

pred gliderVaxWallSeed {
    Configuration.sInfected = -1 -> -1 + 0 -> -1 + 1 -> 0 + -2 -> 0 + 2 -> 0 + -3 -> 0 + 3 -> 1 + -4 -> 1
    Configuration.sRecovered = -1 -> 0 + 0 -> 0 + 1 -> 1+ -2 -> 1 + 2 -> 1 + -3 -> 1 + 3 -> 2 + -4 -> 2
    Configuration.sVaccinated = -4 -> -4 + -3 -> -4 + -2 -> -4 + -1 -> -4 + 0 -> -4 + 1 -> -4 + 2 -> -4 + 3 -> -4
    no Configuration.sDead
    Configuration.sCutoff = `T24
}

// Attempt to find a trace that starts with some infection, 
// and it lasts for at least one state, then dies out!
pred novelTraces {

    no Configuration.sRecovered
    no Configuration.sDead
    Configuration.sCutoff = `T7
    
    // Find a trace the lasts at least...    
    /* 1 */ some i, j: Int { i -> j in Simulation.infected }
    /* 2 */ next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 3 */ next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 4 */ next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 5 */ next_state next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // Steps before dying out

    eventually { no Simulation.infected } 

    initState
    always { deadTimestep[Configuration.sCutoff] }
}

pred fastDeathTraces {

    // Attempt to find most potent diseases, where all cells die in the shortest amount of time.
    no Configuration.sRecovered
    no Configuration.sVaccinated
    #{Configuration.sInfected} < 3
    #{Configuration.sDead} < 3 --dont seem to be owrking correctly, but do seem to restrict the num a bit?
    
    Configuration.sCutoff = `T7
    /* 1 */ some i, j: Int { i -> j in Simulation.infected }
    /* 2 */ next_state { some i, j: Int { i -> j in Simulation.infected } }

    eventually { 
        no Simulation.infected
        no Simulation.susceptible 
        no Simulation.recovered
    } 

    initState
    always { deadTimestep[Configuration.sCutoff] }
}

-- demo vaccinated trace
pred demoVaxTraces {
    Configuration.sVaccinated = 
        0 -> -1 +
        0 -> 0 +
        0 -> 1 +
        0 -> 2
    
    Configuration.sInfected = 
        1 -> -1 + 
        1 -> 1 + 
        1 -> 3
        
    no Configuration.sRecovered
    no Configuration.sDead

    Configuration.sCutoff = `T7
    
    initState
    always { vaxTimestep[Configuration.sCutoff] }
}


pred cyclicTraces {
    no Configuration.sRecovered
    Configuration.sCutoff = `Unreachable
    
    some Simulation.infected

    // It must never be the case that Simulation.infected takes over the whole board, 
    // since this is trivially infected forever :(
    initState
    always { 
        timestep[Configuration.sCutoff]
        some Simulation.infected
        some (Simulation.recovered + Simulation.susceptible)
    }
}

pred oscillator {

    no Configuration.sRecovered
    no Configuration.sDead
    no Configuration.sVaccinated
    Configuration.sCutoff = `T7

    initState

    always {
        timestep[Configuration.sCutoff]
        wellformed
        no Simulation.protected
        no Simulation.vaccinated
        no Simulation.dead
        some Simulation.infected
        some Simulation.susceptible
    }

    next_state {
        (Simulation.infected != Configuration.sInfected) or
        (Simulation.recovered != Configuration.sRecovered) or
        (Simulation.susceptible != Configuration.sSusceptible)
    }

    eventually {
        Simulation.infected = Configuration.sInfected
        Simulation.recovered = Configuration.sRecovered
        Simulation.susceptible = Configuration.sSusceptible
    }
}

pred coreTraces {
    zigSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }
}

pred coreTracesInfectious {
    zigSeed
    initState
    always { 
        wellformed
        timestepMoreInfectious[Configuration.sCutoff] 
    }
}

pred coreTracesRecoveryLong {
    zigSeed
    initState
    always { 
        wellformed
        recoveryTimestep[Configuration.sCutoff] 
    }
}

pred coreTracesdead {
    zigSeed
    initState
    no Configuration.sVaccinated
    no Configuration.sDead
    always { 
        wellformed
        deadTimestep[Configuration.sCutoff] 
    }
}


finiteTrace1: run {
    coreTraces
} for Timeline25

finiteTrace1Infectious: run {
    coreTracesInfectious
} for Timeline25

finiteTrace1dead: run {
    coreTracesdead
} for Timeline25

finiteTrace1LongRecovery: run {
    coreTracesRecoveryLong
} for Timeline25

finiteTrace2: run {

    diag2Seed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

finiteTrace3: run {

    bowSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

workingGliderSmallTrace: run {
    workingGliderSmallSeed
    initState
    always {
        wellformed
        timestep[Configuration.sCutoff]
    }
} for Timeline25

workingGliderBigTrace: run {
    workingGliderBigSeed
    initState
    always {
        wellformed
        timestep[Configuration.sCutoff]
    }
} for Timeline25

gliderVaxWallTrace: run {
    gliderVaxWallSeed
    initState
    always {
        wellformed
        vaxTimestep[Configuration.sCutoff]
    }
} for Timeline25

novelTrace: run {

    novelTraces
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

fastDeathTrace: run {

    fastDeathTraces
    initState
    always { 
        wellformed
        deadTimestep[Configuration.sCutoff] 
    }

} for Timeline25

ChaoticTrace1: run {

    cubeSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

ChaoticTrace2: run {

    gliderSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

ChaoticTrace3: run {

    nabowSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for Timeline25

demoVaxTrace: run {
    demoVaxTraces
} for Timeline25

cyclicTrace: run {
    cyclicTraces 
} for Timeline25

oscillatorTrace: run {
    oscillator
} for Timeline8

pred commonColdSeed {
    all i, j: Int {
        eventually {
            (i -> j) in Simulation.infected
        }
    }

    always { no Simulation.dead }
    eventually { no Simulation.infected }
    initState
    Configuration.sCutoff = `T11
}

commonColdDeadTraces: run {
    commonColdSeed
    
    always { timestep[Configuration.sCutoff ]}
} for Timeline25

pred constantInfectionRate { -- unsat

    always { no Simulation.dead }
    always { #{Simulation.infected} = 3}
    initState
    Configuration.sCutoff = `T11
}

constantInfectionRateTraces: run {
    constantInfectionRate
    
    always { timestep[Configuration.sCutoff ]}
} for Timeline25

// This is trivially unsat if any vax exist, and is identical to the dead case otherwise!
// commonColdVaxTraces: run {
//     commonColdSeed
    
//     always { vaxTimestep[Configuration.sCutoff ]}
//     eventually { no Simulation.infected }
// } for Timeline25

// TRACES WE WANT:
-- Finite length X Traces --> done
-- Cyclic Traces (is this same as oscilattors?)
-- Fast Death Traces --> done-ish, can tweak!!
-- NoVax vs Vax --> done - ish
-- Disease that infects everyone but nobody dies --> in progress

// ????
-- Gliders --> done

