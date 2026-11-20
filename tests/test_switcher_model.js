const fs = require("fs"), vm = require("vm"), assert = require("assert");
const model = vm.createContext({});
vm.runInContext(fs.readFileSync(__dirname + "/../omarchy/.config/omarchy/plugins/personal.switcher/Model.js", "utf8"), model);
const items = [
    {address:"0x1", mapped:true, class:"Chrome", title:"<img src='https://invalid/'>", focusHistoryID:0},
    {address:"0x2", mapped:true, class:"Ghostty", title:"Terminal", focusHistoryID:1},
    {address:"0x3", mapped:true, class:"Chrome", title:"Other", focusHistoryID:2},
    {address:"0x4", mapped:true, class:"Ghostty", title:"Terminal", focusHistoryID:3},
].map(w => ({...w, workspace: {id: 1, name: "1"}}));
assert.equal(model.next(items, 0, 1, false), 1);
assert.equal(model.next(items, 3, 1, false), 0);
assert.equal(model.next(items, 0, -1, false), 3);
assert.equal(model.next(items, 1, 1, true), 3); // highlighted Ghostty, not initial Chrome
assert.equal(model.next(items, 3, 1, true), 1);
assert.equal(model.next([items[0]], 0, 1, true), 0);
assert.equal(model.windows([...items, {mapped:true,address:"bad; command", workspace:{id:1}}], 1).length, 4);
// Fullscreen can make other mapped windows temporarily reject input.
const fullscreenItems = items.map((w, i) => ({...w, fullscreen: i === 0 ? 2 : 0, acceptsInput: i === 0}));
const fullscreenWindows = model.windows([
    ...fullscreenItems,
    {address:"0x5", mapped:false, class:"Closed", acceptsInput:false, workspace:{id:1}},
    {address:"0x6", mapped:true, class:"org.omarchy.screensaver", acceptsInput:true, workspace:{id:1}},
], 1);
assert.deepEqual(Array.from(fullscreenWindows, w => w.address), items.map(w => w.address));
assert.equal(fullscreenWindows[model.next(fullscreenWindows, 0, 1, false)].address, "0x2");
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
// Off-workspace windows never enter the full list or same-app cycling.
// Use numeric IDs: different monitors can reuse workspace display names.
const mixed = [
    {...items[0], address:"0x10", workspace:{id:10, name:"10"}, focusHistoryID:0},
    ...items.slice().reverse(),
    {...items[1], address:"0x11", workspace:{id:11, name:"1"}},
    {...items[0], address:"0x12", workspace:{id:-99, name:"special:test"}},
    {address:"0x13", mapped:true, class:"Chrome"},
];
const local = model.windows(mixed, 1);
assert.deepEqual(Array.from(local, w => w.address), items.map(w => w.address));
assert.deepEqual(Array.from(model.scope(local, "0x1", "Chrome").items, w => w.address), ["0x1", "0x3"]);
assert.equal(model.scope(local, "0x1", null).items.length, 4);
assert.equal(model.windows(mixed, 2).length, 0);
assert.equal(model.windows(mixed, null).length, 0);
assert.equal(model.windows(mixed).length, 0);
assert.deepEqual(Array.from(model.windows(mixed, -99), w => w.address), ["0x12"]);
console.log("Switcher workspace filtering, MRU, wraparound, app filtering, scope restoration and text safety checks passed.");
