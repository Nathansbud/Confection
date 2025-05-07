#lang forge/temporal

sig Timestamp { 
    next: lone Timestamp 
}

-- starting config
one sig Configuration {
    sInfected: set Int -> Int,
    sSusceptible: set Int -> Int,
    sRecovered: set Int -> Int,
    sDead: set Int -> Int,
    sVaccinated: set Int -> Int,
    sIncubation: set Int -> Int -> Int,
    sBounceback: set Int -> Int -> Int,

    sCutoff: one Timestamp
}

-- over each timestep, our simulation should evolve based on the ruleset
one sig Simulation {
    var infected: set Int -> Int,
    var susceptible: set Int -> Int,
    var recovered: set Int -> Int,
    var dead: set Int -> Int,
    var vaccinated: set Int -> Int,

    var incubation: set Int -> Int -> Int,
    var bounceback: set Int -> Int -> Int,

    var protected: set Int -> Int,

    var timestamp: one Timestamp
}

-- returns the successive time stamp
fun nextTimestamp[t: Timestamp]: lone Timestamp {
    t.next
}

-- defines initial state conditions
pred initState {
    -- set simulation = configuration at the start
    Simulation.infected = Configuration.sInfected
    Simulation.incubation = Configuration.sInfected -> (1)
    Simulation.bounceback = Configuration.sRecovered -> (1)
    Simulation.recovered = Configuration.sRecovered
    Simulation.dead = Configuration.sDead
    Simulation.vaccinated = Configuration.sVaccinated
    no Simulation.protected

    -- timestamp starts at T0 based on partial inst
    Simulation.timestamp = `T0
    -- set all remaining cells to susceptible
    all i, j: Int | {
        i -> j not in (
            Simulation.infected + 
            Simulation.recovered +
            Simulation.dead + 
            Simulation.vaccinated
        ) <=> i -> j in Simulation.susceptible
    }
}

-- ensures no cell is in more than one state
pred wellformed { 
    no (Simulation.infected & Simulation.susceptible) 
    no (Simulation.infected & Simulation.recovered)
    no (Simulation.susceptible & Simulation.recovered)
}

-- wellformed with dead cells
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

-- returns number of neighbors that are infected for a cell
fun numInfNeighbors[row, col: Int]: Int {
    let hasNeighbors = {
        ((
            (add[row, -1] + row + add[row, 1]) -> 
            (add[col, -1] + col + add[col, 1])
        ) - (row->col))
        & Simulation.infected
    } | {
        no hasNeighbors => 0
        else {
            #{hasNeighbors} = 0 => -1
            else #{hasNeighbors}
        }
    }
}

-- returns number of neighbors that are vaccinated for a cell
fun numVaxNeighbors[row, col: Int]: Int {
    let hasNeighbors = {
        ((
            (add[row, -1] + row + add[row, 1]) -> 
            (add[col, -1] + col + add[col, 1])
        ) - (row->col))
        & Simulation.vaccinated
    } | {
        no hasNeighbors => 0
        else {
            #{hasNeighbors} = 0 => -1
            else #{hasNeighbors}
        }
    }
}

-- baseline timestep rules with S-I-R cells only, no dead or vaccinated
pred timestep[cutoff: Timestamp] {
    no Simulation.dead
    no Simulation.vaccinated
    no Simulation.protected

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

-- baseline timestep rules with S-I-R cells only, no dead or vaccinated, 
-- higher contagion ruleset !!!
pred timestepMoreInfectious[cutoff: Timestamp] {
    no Simulation.dead
    no Simulation.vaccinated
    no Simulation.protected

    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 1+ infected neighbors, 
        // Infected states stay infected if there are 2+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] not in (0)} |
        let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] not in (0 + 1)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] in (0 + 1)} | {
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

-- added on dead cells to timestep rules
pred deadTimestep[cutoff: Timestamp] {
    no Simulation.protected
    
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

-- added on vax cells to timestep rules
pred vaxTimestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 2+ infected neighbors, 
        // Infected states stay infected if there are 3+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newDead = {row, col: Int | (row->col) in Simulation.infected and Simulation.incubation[row][col] not in (0 + 1 + 2)} |
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] not in (0 + 1)} |
        let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] not in (0 + 1 + 2)} |
        let isProtected = {row, col: Int | (row->col) in Simulation.susceptible and numVaxNeighbors[row, col] not in (0 + 1)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] in (0 + 1 + 2)} |
        let usedInfected = newInfected - isProtected | {
            Simulation.protected' = isProtected
            Simulation.infected' = (usedInfected + stayInfected) - newDead
            Simulation.recovered' = becomeRecover - newDead
            Simulation.dead' = (Simulation.dead + newDead)        
            Simulation.susceptible' = (
                // Recovered cells have a 1-period incubation without immunity considerations
                Simulation.recovered + 
                // Susceptible cells ignore newInfected and newDead
                (Simulation.susceptible - usedInfected)
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
        Simulation.vaccinated' = Simulation.vaccinated
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.infected' = Simulation.infected
        Simulation.susceptible' = Simulation.susceptible
        Simulation.dead' = Simulation.dead
        Simulation.incubation' = Simulation.incubation
        Simulation.vaccinated' = Simulation.vaccinated
        Simulation.recovered' = Simulation.recovered
    }
}

-- added on vax cells to timestep rules
pred recoveryTimestep[cutoff: Timestamp] {
    Simulation.timestamp != cutoff => {
        // Susceptible becomes infected if it has 2+ infected neighbors, 
        // Infected states stay infected if there are 3+ other infected around them,
        // Infected states recover if there is not enough sickness around them
        let newDead = {row, col: Int | (row->col) in Simulation.infected and Simulation.incubation[row][col] not in (0 + 1 + 2)} |
        let doneRecover = {row, col: Int | (row->col) in Simulation.recovered and Simulation.bounceback[row][col] not in (0 + 1 + 2)} |
        let newInfected = {row, col: Int | (row->col) in Simulation.susceptible and numInfNeighbors[row, col] not in (0 + 1)} |
        let stayInfected = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] not in (0 + 1 + 2)} |
        let isProtected = {row, col: Int | (row->col) in Simulation.susceptible and numVaxNeighbors[row, col] not in (0 + 1)} |
        let becomeRecover = {row, col: Int | (row->col) in Simulation.infected and numInfNeighbors[row, col] in (0 + 1 + 2)} |
        let usedInfected = newInfected - isProtected | {
            Simulation.protected' = isProtected
            Simulation.infected' = (usedInfected + stayInfected) - newDead
            Simulation.recovered' = becomeRecover - newDead - doneRecover
            Simulation.dead' = (Simulation.dead + newDead)        
            Simulation.susceptible' = (
                // Recovered cells have a 1-period incubation without immunity considerations
                doneRecover + 
                // Susceptible cells ignore newInfected and newDead
                (Simulation.susceptible - usedInfected)
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

                // I do not believe in this but who knows
                (i -> j) in Simulation.recovered' => {
                    (i -> j) in Simulation.recovered => {
                        Simulation.bounceback'[i][j] = add[1, Simulation.bounceback[i][j]]
                    } else {
                        Simulation.bounceback'[i][j] = 1
                    }
                } else {
                    no Simulation.bounceback'[i][j]
                }
            }
        }

        Simulation.timestamp' = nextTimestamp[Simulation.timestamp]
        Simulation.vaccinated' = Simulation.vaccinated
    } else {
        Simulation.timestamp' = Simulation.timestamp
        Simulation.infected' = Simulation.infected
        Simulation.susceptible' = Simulation.susceptible
        Simulation.dead' = Simulation.dead
        Simulation.incubation' = Simulation.incubation
        Simulation.vaccinated' = Simulation.vaccinated
        Simulation.recovered' = Simulation.recovered
    }
}


