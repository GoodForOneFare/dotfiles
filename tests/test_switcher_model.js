const fs = require("fs"), vm = require("vm"), assert = require("assert");
const model = vm.createContext({});
vm.runInContext(fs.readFileSync(__dirname + "/../omarchy/.config/omarchy/plugins/personal.switcher/Model.js", "utf8"), model);
const items = [
    {address:"0x1", mapped:true, class:"Chrome", title:"<img src='https://invalid/'>", focusHistoryID:0},
    {address:"0x2", mapped:true, class:"Ghostty", title:"Terminal", focusHistoryID:1},
    {address:"0x3", mapped:true, class:"Chrome", title:"Other", focusHistoryID:2},
    {address:"0x4", mapped:true, class:"Ghostty", title:"Terminal", focusHistoryID:3},
];
assert.equal(model.next(items, 0, 1, false), 1);
assert.equal(model.next(items, 3, 1, false), 0);
assert.equal(model.next(items, 0, -1, false), 3);
assert.equal(model.next(items, 1, 1, true), 3); // highlighted Ghostty, not initial Chrome
assert.equal(model.next(items, 3, 1, true), 1);
assert.equal(model.next([items[0]], 0, 1, true), 0);
assert.equal(model.windows([...items, {mapped:true,address:"bad; command"}]).length, 4);
assert(!model.options(items)[0].includes("<"));
assert(!model.options(items)[0].includes(">"));
assert.notEqual(model.options(items)[1], model.options(items)[3]);
const filtered = model.scope(items, "0x2", "Ghostty");
assert.equal(filtered.items.length, 2);
assert(filtered.items.every(w => w.class === "Ghostty"));
assert.equal(filtered.items[filtered.index].address, "0x2");
const other = model.next(filtered.items, filtered.index, 1, false);
assert.equal(filtered.items[other].address, "0x4");
const restored = model.scope(items, filtered.items[other].address, null);
assert.equal(restored.items.length, 4);
assert.equal(restored.items[restored.index].address, "0x4");
assert.equal(model.scope(items, "0x1", "Chrome").items.length, 2);
console.log("Switcher MRU, wraparound, app filtering, scope restoration and text safety checks passed.");
