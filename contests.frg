#lang forge/temporal 

open "confection-core.frg"
open "confection-traces.frg"


-- tinier version of timeline26 for testing purposes
inst timeline3 {
  Timestamp = `T0 + `T1 + `T2 + `Unreachable
  next = `T0 -> `T1  + `T1  -> `T2  + `T2  -> `T0 + `Unreachable -> `Unreachable
}

// pred infNeighborsSeed {
//     Simulation.infected = 
//         // Torodial corners (+ 7 -> 7)
//         -8 -> -8 +
//         -7 -> -7 + 
//         7 -> 7 +
        
//         0 -> 0 + 
//         0 -> 1 + 

//         // Torodial left-right
//         -3 -> -8 + 
//         -3 -> 7 +

//         // Toroidal top-bottom
//         -8 -> 5 + 
//         7 -> 5 +
        
//         2 -> 2 + 2 -> 3 + 2 -> 4 + 
//         3 -> 2 + 3 -> 3 + 3 -> 4 +
//         4 -> 2 + 4 -> 3 + 4 -> 4
// }

// pred nin001     { numInfNeighbors[0, 0] = 1 }
// pred nin111     { numInfNeighbors[0, 1] = 1 }

// pred nin771     { numInfNeighbors[7, 7] = 1 }
// pred ninn8n82   { numInfNeighbors[-8, -8] = 2 }

// pred nin3n81     { numInfNeighbors[-3, -8] = 1 }
// pred nin371      { numInfNeighbors[-3, 7] = 1 }

// pred nin851     { numInfNeighbors[-8, 5] = 1} 
// pred ni751      { numInfNeighbors[7, 5] = 1} 

// pred ni33n7     { numInfNeighbors[3, 3] = -8 }

// test suite for numInfNeighbors {
//     // infNeighborsSeed has various cells initialized to have specific conditions on numInfNeighbors;
//     // read the various predicates as ni-row-col-result w/ n as negative, so ni33n7 => numInfNeighbors[3, 3] = -7
//     assert { infNeighborsSeed } is sufficient for nin001 
//     assert { infNeighborsSeed } is sufficient for nin111 

//     // Enforce to toroidal conditions: edges / corners should wrap!
//     assert { infNeighborsSeed } is sufficient for nin3n81
//     assert { infNeighborsSeed } is sufficient for nin371

//     assert { infNeighborsSeed } is sufficient for nin851
//     assert { infNeighborsSeed } is sufficient for ni751

//     assert { infNeighborsSeed } is sufficient for nin771
//     assert { infNeighborsSeed } is sufficient for ninn8n82

//     // Moore neighborhood consists of 8 cells...but this means we need to consider integer wrap,
//     // as, numInfNeighbors for a fully-filled 3x3 square is -7 (as 8 is not representable)
//     assert { infNeighborsSeed } is sufficient for ni33n7
// }

test suite for wellformed {

    -- infected intersection sus must be empty
    wfNoInfSust: assert {
        wellformed
        Simulation.infected = 0 -> 0
        Simulation.susceptible = 0 -> 0
    } is unsat

    -- infected intersection recovered must be empty
    wfNoInfRec: assert {
        wellformed
        Simulation.infected = 0 -> 0
        Simulation.recovered = 0 -> 0
    } is unsat

    -- susceptible intersection recovered must be empty
    wfNoSusRec: assert {
        wellformed
        Simulation.susceptible = 0 -> 0
        Simulation.recovered = 0 -> 0
    } is unsat

    // Wellformed makes no assertions on deadness
    wellformedNoBehaviorForDead: assert {
        wellformed
        Simulation.infected = 0 -> 0
        Simulation.dead = 0 -> 0
    } is sat

    wfIgnoresVacc: assert {
        wellformed
        Simulation.infected = 0 -> 0
        Simulation.vaccinated = 0 -> 0
    } is sat

    wellformedHolds: assert { 
        Configuration.sCutoff = `Unreachable
        initState
        always {
            wellformed
            timestep[Configuration.sCutoff] 
        }
    } is sat for timeline3

    assert { wellformedDead } is sufficient for wellformed

    -- empty okay for wellformed
    wfEmptyOK: assert { 
        wellformed 
        no Simulation.infected
        no Simulation.susceptible
        no Simulation.recovered
        no Simulation.dead
        no Simulation.vaccinated
        no Simulation.protected
        no Simulation.incubation
    } is sat
}

test suite for wellformedDead {
    assert { wellformed } is necessary for wellformedDead

    wfdNoInfDead: assert {
        wellformedDead
        Simulation.infected = 1 -> 1
        Simulation.dead = 1 -> 1
    } is unsat

    wfdNoSusDead: assert {
        wellformedDead
        Simulation.susceptible = 0 -> 0
        Simulation.dead = 0 -> 0
    } is unsat for timeline3

    wfdNoRecDead: assert {
        wellformedDead
        Simulation.recovered = 0 -> 0
        Simulation.dead = 0 -> 0
    } is unsat for timeline3

    wfdPreserved: assert {
        Configuration.sCutoff = `Unreachable
        initState

        always {
            wellformedDead
            deadTimestep[Configuration.sCutoff]
        }
    } is sat for timeline3
}

test suite for initState {
    // TODO
}

// pred alwaysWellformed { 
//     always { wellformed }
// }

// pred wellformedNext { 
//   no (Simulation.infected' & Simulation.susceptible')
//   no (Simulation.infected' & Simulation.recovered')
//   no (Simulation.susceptible' & Simulation.recovered')
// }

// pred preservedWellformed[tick: Timestamp] { 
//     wellformed and timestep[tick] implies wellformedNext 
// }

// test suite for timestep {

//     coreTracesWellformed: assert {
//         wellformed
//         coreTraces
//     } is sufficient for alwaysWellformed for timeline26


//     timestepAlwaysWellformed: assert { 
//         initState 
//         always { preservedWellformed[Configuration.sCutoff] }
//     } is sat for timeline3 
// }


test suite for deadTimestep {    
    // TODO
}


test suite for vaxTimestep {
    // TODO
}
