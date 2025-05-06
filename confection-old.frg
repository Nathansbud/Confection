#lang forge/temporal

// TODO: transfer remaining relevant traces to confection-traces.frg

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


// Dies out (I think)
pred diag3Seed {
    Configuration.sInfected = 
        0 -> 0 + 1 -> 1 + 2 -> 2 
    
    no Configuration.sRecovered
    Configuration.sCutoff = P
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

    eventually { 
        no Simulation.infected
        no Simulation.susceptible 
        no Simulation.recovered
    } 

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

    eventually { no Simulation.infected and #{Simulation.susceptible} = #{Simulation.dead} and no Simulation.recovered}
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
    lineSeed
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



fastDeathTrace: run {
    fastDeathTraces
}

halfPopDeadTrace: run {
    halfPopDeadTraces
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