# Confection: A Cellular Automata Approach to Disease Modeling

CSCI 1710: Logic for Systems final for Ishika Tulsian, Yali Sommer, and Zack Amiton!

# Base Conway Rules (Implemented @ conway.frg)
[Moore neighborhood with Toroidal boundary conditions]
- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
- Any live cell with two or three live neighbours lives on to the next generation.
- Any live cell with more than three live neighbours dies, as if by overpopulation.
- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

# Disease Model
- Infection rating 1-8
- Depending on infection rating n, any S cell with at least n neightbors will be infected in the next state [S -> I]
- After 2 states, if any I cell has < 3 other I cells neighboring it, it becomes an R cell [I -> R]
- After 1 state, an R cell become an S cell
- An R cell is resistant to infection

# Keystone States
- Discover states where everyone is infected
- Discover states where portions of the population stay infected indefinetly
- Discover shortest states where infection dies out
