// // ⚠️ CONFIGURE THESE PARAMETERS BEFORE HITTING RUN IN STERLING ⚠️ 
// // The behavior of setInterval means that hitting run multiple times will orphan the 
// // interval (which is bound to the window itself) being used to visualize traces,
// // which will result in buggy behavior!
// const LOOP = true;
// const TIME_STEP = 1000;

// let globalIterations = 0;
// const gridSize = 16;

// const offsetHelper = (i) => i + 8;

// let activeInterval = setInterval(() => {
//     const stage = new Stage();

//     const activeIteration = instances[globalIterations];

//     let grid = new Grid({
//         grid_location: {x: 50, y: 50},
//         cell_size: {x_size: 35, y_size: 35},
//         grid_dimensions: {x_size: gridSize, y_size: gridSize}
//     });

//     for(let f of activeIteration._fields) {
//         switch(f._id) {
//             case "infected":
//                 for(let i = 0; i < f._tuples.length; i++) {
//                     const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
//                     const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
//                     grid.add({x: row, y: col}, new Circle({radius: 10, color: "red"}));
//                 }
//                 break;
//             case "susceptible":
//                 for(let i = 0; i < f._tuples.length; i++) {
//                     const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
//                     const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
//                     grid.add({x: row, y: col}, new Circle({radius: 8, color: "blue"}));
//                 }
//                 break;
//             case "recovered":
//                 for(let i = 0; i < f._tuples.length; i++) {
//                     const row = offsetHelper(parseInt(f._tuples[i]._atoms[1]._id));
//                     const col = offsetHelper(parseInt(f._tuples[i]._atoms[2]._id));
//                     grid.add({x: row, y: col}, new Circle({radius: 5, color: "green"}));
//                 }
//                 break;
//             default:
//                 break;

//         }
//     }

//     stage.add(grid);
//     stage.add(new TextBox({
//         text: `Timestep ${globalIterations + 1} / ${instances.length} [${LOOP ? 'Looping' : 'Linear'}]`,
//         coords: {x: 250, y: 20},
//         color: 'black',
//         fontSize: 16
//     }))

//     stage.render(svg, document);
//     globalIterations = (globalIterations + 1) % instances.length;

//     // Just to prevent a memory leak, for now!
//     if(globalIterations == 0 && !LOOP) {
//         clearInterval(activeInterval);
//     }
// }, TIME_STEP);

// ────── CONSTANTS ────────────────────────────────────────────────

const GRID_SIZE = 16;      
const CELL_SIZE = 35;    
const GRID_XY = {x: 50, y: 50}; 
const STATE_COL = {
    susceptible: "#8E8E8E",
    infected: "#FF4500",
    recovered: "#00C96B"};

const BUTTONS = ["PREV", "NEXT"];
const BTN_W = 80;
const BTN_H = 30;
const BTN_Y = GRID_XY.y + GRID_SIZE * CELL_SIZE + 20;              
const BTN_X0 = (GRID_XY.x + GRID_SIZE * CELL_SIZE)/2 - 60;                
// -------------------------------------------------------------------

// Offsets the Forge Int atom ids (-8 to 7) to 0 to 15 indices
const OFFSET = 8;
const shift  = (i) => i + OFFSET;

let index   = 0;                 
const maxT  = instances.length; 
const stage = new Stage(); 

let gridObj;      
let statusBox; 

// ----------------- RENDER GRID --------------------------------------
/**
 * 
 * @param {*} inst 
 * @returns 
 */
function create_grid(inst) {
  const g = new Grid({
    grid_location   : GRID_XY,
    cell_size       : {x_size: CELL_SIZE, y_size: CELL_SIZE},
    grid_dimensions : {x_size: GRID_SIZE,  y_size: GRID_SIZE}
  });

  for (const f of inst._fields) {
    if (!STATE_COL[f._id]) continue;         
    const colour = STATE_COL[f._id];

    for (const tup of f._tuples) {
      const row = shift(parseInt(tup._atoms[1]._id));
      const col = shift(parseInt(tup._atoms[2]._id));

      g.add({x: row, y: col},
            new Rectangle({
              width  : CELL_SIZE,
              height : CELL_SIZE,
              color  : colour
            }));
    }
  }
  return g;
}

/**
 * Draw the board for the current `index`
 */
function render() {
  if (gridObj) stage.remove(gridObj); 
  gridObj = create_grid(instances[index]);
  stage.add(gridObj);

  statusBox.setText(`Timestep ${index+1} / ${maxT}`);
  stage.render(svg, document);
}

// -------------- BUTTON CALLBACKS -----------------------------------

function prevStep() { if (index > 0) { index--; render(); } }
function nextStep() { if (index < maxT-1) { index++; render(); } }

// ---------------- SET UP -------------------------------------------
statusBox = new TextBox({
  text     : `Timestep 1 / ${maxT}`,
  coords   : {x: GRID_XY.x + GRID_SIZE*CELL_SIZE/2, y: 20},
  color    : 'black',
  fontSize : 16
});
stage.add(statusBox);

// create PREV / NEXT buttons
BUTTONS.forEach((label, i) => {
  const x0 = BTN_X0 + i*(BTN_W + 10);

  stage.add(new Rectangle({
    coords : {x: x0, y: BTN_Y},
    width  : BTN_W,
    height : BTN_H,
    color  : '#cccccc'
  }));
  stage.add(new TextBox({
    text     : label,
    coords   : {x: x0 + BTN_W/2, y: BTN_Y + BTN_H/2},
    color    : 'black',
    fontSize : 14,
    events   : [{
      event    : 'click',
      callback : () => {
        (label === "PREV" ? prevStep() : nextStep());
      }
    }]
  }));
});


render();
