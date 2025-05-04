#lang forge/temporal 
open "confection.frg"

pred infNeighborsSeed {
    Simulation.infected = 
        // Torodial corners (+ 7 -> 7)
        -8 -> -8 +
        -7 -> -7 + 
        7 -> 7 +
        
        0 -> 0 + 
        0 -> 1 + 

        // Torodial left-right
        -3 -> -8 + 
        -3 -> 7 +

        // Toroidal top-bottom
        -8 -> 5 + 
        7 -> 5 +
        
        2 -> 2 + 2 -> 3 + 2 -> 4 + 
        3 -> 2 + 3 -> 3 + 3 -> 4 +
        4 -> 2 + 4 -> 3 + 4 -> 4
}

pred nin001     { numInfNeighbors[0, 0] = 1 }
pred nin111     { numInfNeighbors[0, 1] = 1 }

pred nin771     { numInfNeighbors[7, 7] = 1 }
pred ninn8n82   { numInfNeighbors[-8, -8] = 2 }

pred nin3n81     { numInfNeighbors[-3, -8] = 1 }
pred nin371      { numInfNeighbors[-3, 7] = 1 }

pred nin851     { numInfNeighbors[-8, 5] = 1} 
pred ni751      { numInfNeighbors[7, 5] = 1} 

pred ni33n7     { numInfNeighbors[3, 3] = -8 }

test suite for numInfNeighbors {
    // infNeighborsSeed has various cells initialized to have specific conditions on numInfNeighbors;
    // read the various predicates as ni-row-col-result w/ n as negative, so ni33n7 => numInfNeighbors[3, 3] = -7
    assert { infNeighborsSeed } is sufficient for nin001 
    assert { infNeighborsSeed } is sufficient for nin111 

    // Enforce to toroidal conditions: edges / corners should wrap!
    assert { infNeighborsSeed } is sufficient for nin3n81
    assert { infNeighborsSeed } is sufficient for nin371

    assert { infNeighborsSeed } is sufficient for nin851
    assert { infNeighborsSeed } is sufficient for ni751

    assert { infNeighborsSeed } is sufficient for nin771
    assert { infNeighborsSeed } is sufficient for ninn8n82

    // Moore neighborhood consists of 8 cells...but this means we need to consider integer wrap,
    // as, numInfNeighbors for a fully-filled 3x3 square is -7 (as 8 is not representable)
    assert { infNeighborsSeed } is sufficient for ni33n7
}

test suite for wellformed {

}

test suite for wellformedDead {

}

test suite for timestep {

}

test suite for deadTimestep {    

}

