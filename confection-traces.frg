#lang forge/temporal

open "confection-core.frg"

option run_sterling "con-visualizer.js"
option max_tracelength 26

/*
insert file description
*/


-- partial instance to define sequence of time stamps. 
-- next relation ensures theres a loop the sequence to work with temporal forge
-- optimizes with the solver for fast trace times
inst timeline26 {
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
        0 -> 0 + 0 -> 4 + 
        2 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T15
}

-- doesn't recover within 25 steps, cool pattern though
pred nabowSeed {
    Configuration.sInfected =
        -1 -> 0 + -1 -> 4 + 
        0 -> 2
    
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

-- demo vaccinated trace
pred demoVaxTraces {
    Configuration.sVaccinated = 
        0 -> 0 +
        0 -> 1 +
        0 -> 2 +
        0 -> 3
    
    Configuration.sInfected = 
        1 -> 0 + 
        1 -> 2 + 
        1 -> 4
        
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

pred coreTraces {
    zigSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }
}

finiteTrace1: run {
    coreTraces
} for timeline26

finiteTrace2: run {

    diag2Seed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

finiteTrace3: run {

    bowSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

novelTrace: run {

    novelTraces
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

ChaoticTrace1: run {

    cubeSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

ChaoticTrace2: run {

    gliderSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

ChaoticTrace3: run {

    nabowSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

demoVaxTrace: run {
    demoVaxTraces
} for timeline26

cyclicTrace: run {
    cyclicTraces 
} for timeline26



// TRACES WE WANT:
-- Finite length X Traces
-- Cyclic Traces (is this same as oscilattors?)
-- Fast Death Traces
-- NoVax vs Vax
-- "Herd Immunity" (vax seed prevents spread)
-- Disease that infects everyone but nobody dies

// ????
-- Gliders??

// rip
-- nondeterminism