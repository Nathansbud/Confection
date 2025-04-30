#lang forge/temporal

option run_sterling "con-visualizer.js"

option max_tracelength 16
// Quick Guide: 
// D = 4
// H = 8
// J = 10
// P = 16
// T = 20

abstract sig Modality {}

// For Conway, we have Alive, Dead; for SIR, we also consider remission states
one sig Alive, Dead extends Modality {} 
// sig Remission extends Modality {
//     timer: Int
// }

abstract sig Timestamp {}
one sig A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z extends Timestamp {}

// Our starting configuration, ideally initialized via CLI input (todo)
one sig Configuration {
    sInfected: set Int -> Int,
    sSusceptible: set Int -> Int,
    sRecovered: set Int -> Int,
    
    // Must be ≤ max_tracelength for non-lasso traces to ensure a lasso
    // is generated
    sCutoff: one Timestamp
}

// Over each timestep, our simulation should evolve based on the game of life ruleset
one sig Simulation {
    var infected: set Int -> Int,
    var susceptible: set Int -> Int,
    var recovered: set Int -> Int,
    
    var timestamp: one Timestamp
}

fun nextTimestamp[s: Timestamp]: Timestamp {
    (A -> B + B -> C + C -> D + D -> E + E -> F + F -> G + G -> H + H -> I + I -> J + J -> K + K -> L + L -> M + M -> N + N -> O + O -> P + P -> Q + Q -> R + R -> S + S -> T + T -> U + U -> V + V -> W + W -> X + X -> Y + Y -> Z)[s]
}


pred initState {
    Simulation.infected = Configuration.sInfected
    Simulation.recovered = Configuration.sRecovered
    Simulation.timestamp = A
    all i, j: Int | {
        i -> j not in (Simulation.infected + Simulation.recovered) <=> i -> j in Simulation.susceptible
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

// fun numInfNeighbors[row, col: Int]: Int {
//     #{(add[row, -1]-> add[col, -1]) & Simulation.infected + 
//     (add[row, -1]-> col) & Simulation.infected + 
//     (add[row, -1]-> add[col, 1]) & Simulation.infected + 
//     (add[row, 1]-> add[col, -1]) & Simulation.infected + 
//     (add[row, 1]-> col) & Simulation.infected + 
//     (add[row, 1]-> add[col, 1]) & Simulation.infected + 
//     (row-> add[col, -1]) & Simulation.infected + 
//     (row-> col) & Simulation.infected +
//     (row-> add[col, 1]) & Simulation.infected
//     }   
// }

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
        // let susNeighbors = neighbors[Simulation.susceptible] | 
        let infNeighbors = neighbors[Simulation.infected] | {
            // TODO: THIS IS NOT RIGHT LOGIC :(
            // We need the neighbors 


            // Susceptible becomes infected if it has 2+ infected neighbors, 
            // Infected states stay infected if there are 3+ other infected around them,
            // Infected states recover if there is not enough sickness around them
            let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] > 1} |
            let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] > 2} |
            let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] < 3} | {
                Simulation.infected' = newInfected + stayInfected
                Simulation.recovered' = becomeRecover
                Simulation.susceptible' = Simulation.recovered + (Simulation.susceptible - newInfected)
            }
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
    // GETTING UNSAT WHEN NOT DOING H, TRIED J, Y, Z
}

pred coreTraces {
    cubeSeed
    initState

    always { timestep[Configuration.sCutoff] }
}

demoTrace: run {
    coreTraces
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

