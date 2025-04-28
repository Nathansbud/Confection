// ⚠️ CONFIGURE THESE PARAMETERS BEFORE HITTING RUN IN STERLING ⚠️ 
// The behavior of setInterval means that hitting run multiple times will orphan the 
// interval (which is bound to the window itself) being used to visualize traces,
// which will result in buggy behavior!
const LOOP = true;
const TIME_STEP = 1000;

let globalIterations = 0;
const gridSize = 16;

const offsetHelper = (i) => i + 8;

let activeInterval = setInterval(() => {
    const stage = new Stage();

    const activeIteration = instances[globalIterations];

    let grid = new Grid({
        grid_location: {x: 50, y: 50},
        cell_size: {x_size: 35, y_size: 35},
        grid_dimensions: {x_size: gridSize, y_size: gridSize}
    });

    for(let f of activeIteration._fields) {
        switch(f._id) {
            case "infected":
                for(let i = 0; i < f._tuples.length; i++) {
                    const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
                    const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
                    grid.add({x: row, y: col}, new Circle({radius: 10, color: "red"}));
                }
                break;
            case "susceptible":
                for(let i = 0; i < f._tuples.length; i++) {
                    const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
                    const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
                    grid.add({x: row, y: col}, new Circle({radius: 8, color: "blue"}));
                }
                break;
            case "recovered":
                for(let i = 0; i < f._tuples.length; i++) {
                    const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
                    const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
                    grid.add({x: row, y: col}, new Circle({radius: 5, color: "green"}));
                }
                break;
            default:
                break;

        }
    }

    stage.add(grid);
    stage.add(new TextBox({
        text: `Timestep ${globalIterations + 1} / ${instances.length} [${LOOP ? 'Looping' : 'Linear'}]`,
        coords: {x: 250, y: 20},
        color: 'black',
        fontSize: 16
    }))

    stage.render(svg, document);
    globalIterations = (globalIterations + 1) % instances.length;

    // Just to prevent a memory leak, for now!
    if(globalIterations == 0 && !LOOP) {
        clearInterval(activeInterval);
    }
}, TIME_STEP);
