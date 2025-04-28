#lang forge/temporal

option run_sterling "visualizer.js"

option max_tracelength 8

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
    sLiving: set Int -> Int,
    sRemission: set Int -> Int,
    sCutoff: one Timestamp
}

// Over each timestep, our simulation should evolve based on the game of life ruleset
one sig Simulation {
    var living: set Int -> Int,
    var remission: set Int -> Int,
    var timestamp: one Timestamp
}

fun nextTimestamp[s: Timestamp]: Timestamp {
    (A -> B + 
     B -> C + 
     C -> D + 
     D -> E + 
     E -> F + 
     F -> G + 
     G -> H + 
     H -> I + 
     I -> J + 
     J -> K + 
     K -> L + 
     L -> M + 
     M -> N + 
     N -> O + 
     O -> P + 
     P -> Q + 
     Q -> R + 
     R -> S + 
     S -> T + 
     T -> U + 
     U -> V + 
     V -> W + 
     W -> X + 
     X -> Y + 
     Y -> Z)[s]
}

pred initState {
    Simulation.living = Configuration.sLiving
    Simulation.remission = Configuration.sRemission
    Simulation.timestamp = A
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

pred timestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        let neigh = neighbors[Simulation.living] | {
            let reproduce = {row, col: Int | (row->col) not in Simulation.living and #neigh[row][col] = 3} |
            let survival = {row, col: Int | (row->col) in Simulation.living and #neigh[row][col] in (2 + 3)} |
            
            Simulation.living' = reproduce + survival
        }

        Simulation.timestamp' = nextTimestamp[Simulation.timestamp] 
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.living' = Simulation.living
        Simulation.remission' = Simulation.remission
    }
}

// 2-by-2 cube is a stable configuration; {(A, B), (A + 1, B), (A, B + 1)} will result
// in a neighborhood of size 3 for (A + 1, B + 1), which will spawn, and then create the stable 
// grid, resulting in a 2-step stable configuration!
pred cubeSeed { 
    Configuration.sLiving = 
        0 -> 0 + 
        0 -> 1 +
        1 -> 0
    
    Configuration.sCutoff = D
}

pred gliderSeed {
    Configuration.sLiving = 
        0 -> 1 +
        1 -> 2 + 
        2 -> 0 + 2 -> 1 + 2 -> 2

    Configuration.sCutoff = H
}

pred coreTraces {
    gliderSeed
    initState

    always { timestep[Configuration.sCutoff] }
}

demoTrace: run {
    coreTraces
} 
