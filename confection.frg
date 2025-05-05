#lang forge/temporal

option run_sterling "con-visualizer.js"
option max_tracelength 8
// Quick Guide: 
// D = 4
// H = 8
// J = 10
// P = 16
// T = 20
// X = 24

abstract sig Timestamp {}
one sig A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z extends Timestamp {}
one sig Unreachable, Ignored extends Timestamp {}

// MAJOR TODOS:
// - Figure out ruleset that is interesting
// - Write traces w/ emergent behavior (e.g. dies out, does not die out, remains alive but does not spread)
// - Decide alternate rulesets to find interesting properties (e.g. "is there a ruleset that lives for 3 generations then dies out?")
// ...and so on!

// Our starting configuration, ideally initialized via CLI input (todo)
one sig Configuration {
    sInfected: set Int -> Int,
    sSusceptible: set Int -> Int,
    sRecovered: set Int -> Int,
    sDead: set Int -> Int,
    sIncubation: set Int -> Int -> Int,

    // Must be ≤ max_tracelength for non-lasso traces to ensure a lasso
    // is generated
    sCutoff: one Timestamp
}

// Over each timestep, our simulation should evolve based on the game of life ruleset
one sig Simulation {
    var infected: set Int -> Int,
    var incubation: set Int -> Int -> Int,

    var susceptible: set Int -> Int,
    var recovered: set Int -> Int,
    var dead: set Int -> Int,

    var timestamp: one Timestamp
}

fun nextTimestamp[s: Timestamp]: Timestamp {
    (
        A -> B + B -> C + C -> D + D -> E + E -> F + F -> G + G -> H + H -> I + I -> J + J -> K + K -> L + L -> M + M -> N + N -> O + O -> P + P -> Q + Q -> R + R -> S + S -> T + T -> U + U -> V + V -> W + W -> X + X -> Y + Y -> Z +
        // Add Unreachable to tag things that should not be given a timestamp in case of > 26 timesteps
        Z -> A + Unreachable -> Unreachable + Ignored -> Ignored
    )[s]
}

pred initState {
    Simulation.infected = Configuration.sInfected
    Simulation.incubation = Configuration.sInfected -> (1)
    Simulation.recovered = Configuration.sRecovered
    Simulation.dead = Configuration.sDead
    Simulation.timestamp = ((Configuration.sCutoff != Unreachable) => { A } else { Ignored })
    
    all i, j: Int | {
        i -> j not in (
            Simulation.infected + 
            Simulation.recovered +
            Simulation.dead
        ) <=> i -> j in Simulation.susceptible
    }
}

// Logic adapted from https://github.com/tnelson/Forge/blob/main/forge/examples/basic/gameOfLife.frg,
// as a means to create the relation: (A, B) -> (C, D) for all neighbors (C, D) around (A, B)
fun neighbors[center: Int -> Int]: Int -> Int -> Int -> Int {
    { row, col, dr, dc: Int | 
        let rows = (add[row, 1] + row + add[row, -1]) |
        let cols = (add[col, 1] + col + add[col, -1]) |
        // Takes the set of row / cols ± 1 from the current cell, and then 
        // weeds out the center cell and concats (A, B) -> (C, D)
        (dr->dc) in (center & ((rows->cols) - (row->col)))
    }
}

fun numInfNeighbors[row, col: Int]: Int {
    #{
        ((
            (add[row, -1] + row + add[row, 1]) -> 
            (add[col, -1] + col + add[col, 1])
        ) - (row->col))
        & Simulation.infected
    }
}

pred timestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 2+ infected neighbors, 
        // Infected states stay infected if there are 3+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] not in (0 + 1)} |
        let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] not in (0 + 1 + 2)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] in (0 + 1 + 2)} | {
            Simulation.infected' = newInfected + stayInfected
            Simulation.recovered' = becomeRecover
            Simulation.susceptible' = Simulation.recovered + (Simulation.susceptible - newInfected)
        }

        Simulation.timestamp' = nextTimestamp[Simulation.timestamp]
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.infected' = Simulation.infected
        Simulation.incubation' = Simulation.incubation
        Simulation.susceptible' = Simulation.susceptible
        Simulation.dead' = Simulation.dead
        Simulation.recovered' = Simulation.recovered
    }
}

pred wellformedDead {
    // No pairwise intersection between sets; if this is ever not the case,
    // something is greviously wrongs
    no (Simulation.infected & Simulation.susceptible) 
    no (Simulation.infected & Simulation.recovered)
    no (Simulation.infected & Simulation.dead)
    no (Simulation.susceptible & Simulation.recovered)
    no (Simulation.susceptible & Simulation.dead)
    no (Simulation.recovered & Simulation.dead)
}

pred wellformed { 
    no (Simulation.infected & Simulation.susceptible) 
    no (Simulation.infected & Simulation.recovered)
    no (Simulation.susceptible & Simulation.recovered)
}

pred deadTimestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 2+ infected neighbors, 
        // Infected states stay infected if there are 3+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newDead = {row, col: Int | (row->col) in Simulation.infected and Simulation.incubation[row][col] not in (0 + 1 + 2)} |
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] not in (0 + 1)} |
        let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] not in (0 + 1 + 2)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] in (0 + 1 + 2)} | {
            Simulation.infected' = (newInfected + stayInfected) - newDead
            Simulation.recovered' = becomeRecover - newDead
            Simulation.dead' = (Simulation.dead + newDead)        
            Simulation.susceptible' = (
                // Recovered cells have a 1-period incubation without immunity considerations
                Simulation.recovered + 
                // Susceptible cells ignore newInfected and newDead
                (Simulation.susceptible - newInfected)
            )

            // @ Ishika or Yali is there a better way to do this lol, I tried to do 
            //      Simulation.incubation'[newInfected] = 1
            //      all s: stayInfected { Simulation.incubation'[s] = add[1, Simulation.incubation[s]] }
            // ... but that did not work :(
            
            // ...increase / initialize incubations
            all i, j: Int {
                (i -> j) in Simulation.infected' => {
                    (i -> j) in stayInfected => {
                        Simulation.incubation'[i][j] = add[1, Simulation.incubation[i][j]]
                    } else {
                        Simulation.incubation'[i][j] = 1
                    }
                } else {
                    no Simulation.incubation'[i][j]
                } 
            }
        }

        Simulation.timestamp' = nextTimestamp[Simulation.timestamp]
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.infected' = Simulation.infected
        Simulation.susceptible' = Simulation.susceptible
        Simulation.dead' = Simulation.dead
        Simulation.incubation' = Simulation.incubation
        Simulation.recovered' = Simulation.recovered
    }
}

pred bbTimestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 2+ infected neighbors, 
        // Infected states stay infected if there are 3+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] in (2)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected} | {
            Simulation.infected' = newInfected
            Simulation.recovered' = becomeRecover
            Simulation.susceptible' = Simulation.recovered + (Simulation.susceptible - newInfected)
        }

        Simulation.timestamp' = nextTimestamp[Simulation.timestamp]
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.infected' = Simulation.infected
        Simulation.susceptible' = Simulation.susceptible
        Simulation.recovered' = Simulation.recovered
    }
}

// 2-by-2 cube is a stable configuration; {(A, B), (A + 1, B), (A, B + 1)} will result
// in a neighborhood of size 3 for (A + 1, B + 1), which will spawn, and then create the stable 
// grid, resulting in a 2-step stable configuration!
pred cubeSeed { 
    Configuration.sInfected = 
        0 -> 0 + 
        0 -> 1 +
        1 -> 0

    no Configuration.sRecovered
    Configuration.sCutoff = P
}

pred gliderSeed {
    Configuration.sInfected = 
        0 -> 1 +
        1 -> 2 + 
        2 -> 0 + 2 -> 1 + 2 -> 2

    Configuration.sCutoff = H
}

pred infectionSeed {
    Configuration.sInfected = 
        0 -> 1 +
        1 -> 2 + 
        2 -> 0 + 2 -> 1 + 2 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = H
}

pred radialSeed {
    // Under 2-3 ruleset, this should be self-sustaining
    Configuration.sInfected = 
        0 -> 0 + 0 -> 1 + 0 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

pred baseballSeed {
    Configuration.sInfected = 
        0 -> 0 + 0 -> 2 + 
        2 -> 0 + 2 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

pred lineSeed {
    Configuration.sInfected = 
        0 -> 0 + 0 -> 2 + 0 -> 4
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

// Dies out!
pred diag2Seed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

// Dies out (I think)
pred diag3Seed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1 + 2 -> 2 
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

// Longest seed I found to die out...
pred bowSeed {
    Configuration.sInfected = 
        0 -> 0 + 0 -> 4 + 
        2 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
}

// Might? Die out if given enough time to run...but 24 seems to kill things :(
pred nabowSeed {
    Configuration.sInfected =
        0 -> 0 + 0 -> 4 + 
        1 -> 2
    
    no Configuration.sRecovered
    Configuration.sCutoff = X
}

pred zigSeed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1 + 
        0 -> 2

    no Configuration.sRecovered
    Configuration.sCutoff = P
}

pred coreTraces {
    zigSeed
    
    initState
    always { timestep[Configuration.sCutoff] }
}
 
pred novelTraces {
    // Attempt to find a trace that starts with some infection, 
    // and it lasts for at least one state, then dies out!
    no Configuration.sRecovered
    Configuration.sCutoff = P
    
    // Find a trace the lasts at least...    
    /* 1 */ some i, j: Int { i -> j in Simulation.infected }
    /* 2 */ next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 3 */ next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 4 */ next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 5 */ next_state next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // Steps before dying out

    eventually { no Simulation.infected } 

    initState
    always { timestep[Configuration.sCutoff] }
}

pred fastDeathTraces {

    // Attempt to find most potent diseases, where all cells die in the shortest amount of time.
    no Configuration.sRecovered
    Configuration.sCutoff = H   
    /* 1 */ some i, j: Int { i -> j in Simulation.infected }
    /* 2 */ next_state { some i, j: Int { i -> j in Simulation.infected } }

    //ONCE ITS RUNNING, I WANT TO RESTRICT THE # OF CELLS IN THE INIT STATE, SO THAT ITS NOT JUST ALL INFECTED AS A SEED. LIKE #(INFECTED) < 16?

    // /* 3 */ next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // /* 4 */ next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // /* 5 */ next_state next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // Steps before all dead, still decidiing how many necessary

    eventually { no Simulation.infected and no Simulation.susceptible and no Simulation.recovered} 

    initState
    always { deadTimestep[Configuration.sCutoff] }
}

pred halfPopDeadTraces {

    // Attempt to find a disease eliminating exactly half the population
    no Configuration.sRecovered
    Configuration.sCutoff = H   
    /* 1 */ some i, j: Int { i -> j in Simulation.infected }
    /* 2 */ next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 3 */ next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 4 */ next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    /* 5 */ next_state next_state next_state next_state { some i, j: Int { i -> j in Simulation.infected } }
    // Steps before end

    eventually { no Simulation.infected and #{Simulation.susceptible} = 32 and no Simulation.recovered and #{Simulation.dead} = 32} 
    initState
    always { deadTimestep[Configuration.sCutoff] }
}



pred cyclicTraces {
    no Configuration.sRecovered
    Configuration.sCutoff = Unreachable
    
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

pred bOscillatorSeed {
    Configuration.sInfected = 
        0 -> 0 + 0 -> 1 +
        1 -> 0 + 1 -> 1
    
    Configuration.sRecovered = 
        0 -> -1 + 
        1 -> 2 + 
        2 -> 0 + 
        -1 -> 1

    Configuration.sCutoff = Unreachable
}

pred brainOscillatorTraces {
    bOscillatorSeed
    
    initState
    always { bbTimestep[Configuration.sCutoff] }
}

pred diesSeed {
    Configuration.sInfected =
        0 -> 0 + 0 -> 1 +
        1 -> 0 + 1 -> 1
    
    no Configuration.sDead
    no Configuration.sRecovered
    Configuration.sCutoff = H
}

pred diesTrace {
    diesSeed
    initState
    always { deadTimestep[Configuration.sCutoff] }
}

pred twoGroupSpreadSeed {
    Configuration.sInfected =
        0 -> -1 + 0 -> 1 +
        1 -> -1 + 1 -> 1
    
    no Configuration.sDead
    no Configuration.sRecovered
    Configuration.sCutoff = X
}

pred twoGroupSpread {
    twoGroupSpreadSeed
    initState
    always { deadTimestep[Configuration.sCutoff] }
}

pred triangleSeed {
    Configuration.sInfected =
        0 -> -1 + 0 -> 1 +
        0 -> 0 + 0 -> -2 +
        0 -> 2 + 1 -> 2 + 
        1 -> -2 + 2 -> -1 +
        2 -> 1 + 3 -> 0
    
    no Configuration.sDead
    no Configuration.sRecovered
    Configuration.sCutoff = X
}

pred triangleSpread {
    triangleSeed
    initState
    always { deadTimestep[Configuration.sCutoff] }
}

pred longLineSeed {
    Configuration.sInfected =
        0 -> -1 + 1 -> 0 +
        2 -> -1 + 3 -> 0 +
        4 -> -1 + 5 -> 0 + 
        6 -> -1 + 7 -> 0 +
        -8 -> -1 + -7 -> 0 + 
        -6 -> -1 + -5 -> 0 +
        -4 -> -1 + -3 -> 0 +
        -2 -> -1 + -1 -> 0
    
    no Configuration.sDead
    no Configuration.sRecovered
    Configuration.sCutoff = X
}

pred longLineSpread {
    longLineSeed
    initState
    always { deadTimestep[Configuration.sCutoff] }
}

//seed where everyone dies besides the initial infected population.
pred allDeadButInitInfectedSeed { // still seeing the bug with dead cells moving here
    Configuration.sInfected =
        -8 -> -8 + -7 -> -7 +
        -6 -> -6 + -5 -> -5 +
        -4 -> -4 + -3 -> -3 + 
        -2 -> -2 + -1 -> -1 +
        0 -> 0 + 1 -> 1 + 
        2 -> 2 + 3 -> 3 +
        4 -> 4 + 5 -> 5 +
        6 -> 6 + 7 -> 7
    
    no Configuration.sDead
    no Configuration.sRecovered
    Configuration.sCutoff = X
}

pred allDeadButInitInfectedSpread {
    allDeadButInitInfectedSeed
    initState
    always { deadTimestep[Configuration.sCutoff] }
}


demoTrace: run {
    coreTraces
} 

novelTrace: run {
    novelTraces
}

fastDeathTrace: run {
    fastDeathTraces
}

halfPopDeadTrace: run {
    halfPopDeadTraces
}

cyclicTrace: run {
    cyclicTraces
}

deadTrace: run {
    diesTrace
}

twoGroupSpreadTrace: run {
    twoGroupSpread
}

triangleTrace: run {
    triangleSpread
}

longLineTrace: run {
    longLineSpread
}

allDeadButInitInfectedTrace: run {
    allDeadButInitInfectedSpread
}

brainTrace: run {
    brainOscillatorTraces
}


-- Talk with Tim:
// things to do
    // extreme case -> will die
    // vaccinated? 
    // maybe immune unless stronger contagion condition applies
    // different consequences of different shapes of disease
    // related work obligations that he wants to hear about
    // say what you can model and can't

    // synthesise a starting board such that you protect the vulnerable cells?
    // glider: infection that remains endemic 
    // explore consequences of different rules

// non-determinism gets much harder --> but do these things instead:
    -- find me a trace that exhibits a 30% infection rate? 
    -- count number of infections and take percent?

// for capstone:
    -- help understanding related work and how that compares with your model


// for temporal to fix the looping situation:
    -- do nothing guard pred to play the non loop 
    -- USE partial inst !!!!!

