#lang forge/temporal

option run_sterling "visualizer.js"

// option max_tracelength 16
// option min_tracelength 16

abstract sig Modality {}

// For Conway, we have Alive, Dead; for SIR, we also consider remission states
one sig Alive, Dead extends Modality {} 
// sig Remission extends Modality {
//     timer: Int
// }

// Our starting configuration, ideally initialized via CLI input (todo)
one sig Configuration {
    sLiving: set Int -> Int,
    sRemission: set Int -> Int
}

// Over each timestep, our simulation should evolve based on the game of life ruleset
one sig Simulation {
    var living: set Int -> Int,
    var remission: set Int -> Int
}

pred initState {
    Simulation.living = Configuration.sLiving
    Simulation.remission = Configuration.sRemission
}

// Logic adapted from https://github.com/tnelson/Forge/blob/main/forge/examples/basic/gameOfLife.frg,
// as a means to create the relation: (A, B) -> (C, D) for all neighbors (C, D) around (A, B)
fun neighbors[center: Int -> Int]: Int -> Int -> Int -> Int {
    { row, col, dr, dc: Int | 
        let rows = (add[row, 1] + row + add[row, -1]) |
        let cols = (add[col, 1] + col + add[col, -1]) |
        (dr->dc) in (center & ((rows->cols) - (row->col)))
    }
}

pred timestep {
    let neigh = neighbors[Simulation.living] | {
        let reproduce = {row, col: Int | (row->col) not in Simulation.living and #neigh[row][col] = 3} |
        let survival = {row, col: Int | (row->col) in Simulation.living and #neigh[row][col] in (2 + 3)} |
        
        Simulation.living' = reproduce + survival
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
}

pred coreTraces {
    cubeSeed
    initState
    
    // always { validState }
    always { timestep }
}

demoTrace: run {
    coreTraces
} 
