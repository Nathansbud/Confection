// ────── CONSTANTS ────────────────────────────────────────────────
const GRID_SIZE = 8;      
const CELL_SIZE = 35;    
const GRID_XY = {x: 50, y: 50}; 
const STATE_COL = {
    susceptible: "#8E8E8E",
    infected: "#FF4500",
    recovered: "#00C96B",
    dead: "#000000",
    vaccinated: "#0093D5",
    protected: "#a000c8"
};

const BUTTONS = {
  "PREV": prevStep,
  "NEXT": nextStep,
  "RESET": reset
}
const BTN_W = 80;
const BTN_H = 30;
const BTN_Y = GRID_XY.y + GRID_SIZE * CELL_SIZE + 20;
const BTN_X0 = (GRID_XY.x + GRID_SIZE * CELL_SIZE)/2 - 90;                
// -------------------------------------------------------------------

// Offsets the Forge Int atom ids (-8 to 7) to 0 to 15 indices
const OFFSET = 4;
const shift = (i) => i + OFFSET;

let index = 0;                 
const maxT = instances.length; 
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
    grid_location: GRID_XY,
    cell_size: {x_size: CELL_SIZE, y_size: CELL_SIZE},
    grid_dimensions: {x_size: GRID_SIZE,  y_size: GRID_SIZE}
  });


  for (const f of inst._fields) {
    if (f._id === "protected") continue;
    if (!STATE_COL[f._id]) continue; 

    const fill = STATE_COL[f._id];

    for (const tup of f._tuples) {
      const row = shift(+tup._atoms[1]._id);
      const col = shift(+tup._atoms[2]._id);

      g.add({x: row, y: col},
            new Rectangle({
              width: CELL_SIZE,
              height: CELL_SIZE,
              color: fill
            }));
    }
  }

  // creates the protected purple outline on the cells
  const protField = inst._fields.find(f => f._id === "protected");
  if (protField) {
    for (const tup of protField._tuples) {
      const row = shift(+tup._atoms[1]._id);
      const col = shift(+tup._atoms[2]._id);

      g.add({x: row, y: col},
            new Rectangle({
              width: CELL_SIZE,
              height: CELL_SIZE,
              color: "none",
              borderColor: STATE_COL.protected,
              borderWidth: 3
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
function reset() { index = 0; render(); }

// ---------------- SET UP -------------------------------------------
statusBox = new TextBox({
  text: `Timestep 1 / ${maxT}`,
  coords: {x: GRID_XY.x + GRID_SIZE*CELL_SIZE/2, y: 20},
  color: 'black',
  fontSize: 16
});
stage.add(statusBox);

// create PREV / NEXT buttons
Object.keys(BUTTONS).forEach((label, i) => {
  const x0 = BTN_X0 + i*(BTN_W + 10);

  stage.add(new Rectangle({
    coords: {x: x0, y: BTN_Y},
    width: BTN_W,
    height: BTN_H,
    color: '#cccccc'
  }));

  stage.add(new TextBox({
    text: label,
    coords: {x: x0 + BTN_W/2, y: BTN_Y + BTN_H/2},
    color: 'black',
    fontSize: 14,
    events: [{
      event: 'click',
      callback: BUTTONS[label]
    }]
  }));
});


render();
