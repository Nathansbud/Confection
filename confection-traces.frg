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
    `T24

    next = `T0 -> `T1  + `T1  -> `T2  + `T2  -> `T3  + `T3  -> `T4 +
    `T4 -> `T5  + `T5  -> `T6  + `T6  -> `T7  + `T7  -> `T8 +
    `T8 -> `T9  + `T9  -> `T10 + `T10 -> `T11 + `T11 -> `T12 +
    `T12 -> `T13 + `T13 -> `T14 + `T14 -> `T15 + `T15 -> `T16 +
    `T16 -> `T17 + `T17 -> `T18 + `T18 -> `T19 + `T19 -> `T20 +
    `T20 -> `T21 + `T21 -> `T22 + `T22 -> `T23 + `T23 -> `T24 +
    `T24 -> `T0 
}

-- stable seed, population recovers fully within 8 steps
pred zigSeed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1 + 
        0 -> 2

    no Configuration.sRecovered
    Configuration.sCutoff = `T7
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

pred diag2Seed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1
    
    no Configuration.sRecovered
    Configuration.sCutoff = `T7
}


finiteTrace1: run {

    zigSeed
    initState
    always { 
        wellformed
        timestep[Configuration.sCutoff] 
    }

} for timeline26

finiteTrace2: run {

    diag2Seed
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