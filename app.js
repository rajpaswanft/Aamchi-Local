/* Mumbai Local – single-page app, no build step, works from file:// */
"use strict";

/* ============ 1. DATA ============
   Expected JSON (same as your spec):
   { stations:[{station_id,station_name,line_type,station_code,platform_count}],
     trains:[{train_id,train_number,train_name,source,destination,train_type,is_ac,is_ladies_special,cars}],
     schedules:[{train_id,station_id,arrival_time,departure_time,platform_number,halt_sequence,distance_km?}] }
   Times can be "HH:MM" (use "00:10+1" for after midnight) or minutes since midnight.
   Until you load real data (Load JSON button), a DEMO timetable is generated below.
   DEMO times are illustrative, NOT the real Railway timetable. */

function buildDemo() {
  const lines = {
    WESTERN: [["Churchgate","CCG",0,1],["Mumbai Central","MMCT",8,1],["Mahim","MM",15,0],["Dadar (WR)","DDR",12,1],
      ["Bandra","BA",17,1],["Andheri","ADH",22,1],["Goregaon","GMN",26,0],["Borivali","BVI",30,1],["Virar","VR",60,1]],
    CENTRAL: [["CSMT","CSTM",0,1],["Byculla","BY",3,0],["Dadar (CR)","DR",9,1],["Kurla","CLA",16,1],
      ["Ghatkopar","GC",20,0],["Thane","TNA",34,1],["Dombivli","DI",47,0],["Kalyan","KYN",54,1]],
  };
  // Keep only stops in ascending km order
  const stations = [], trains = [], schedules = []; let sid = 1, tid = 1000;
  for (const [line, defs] of Object.entries(lines)) {
    const stops = defs.map(([name, code, km, fast]) => ({ id: sid++, name, code, km, fast }));
    stops.sort((a, b) => a.km - b.km);
    stops.forEach(s => stations.push({ station_id: s.id, station_name: s.name, line_type: line, station_code: s.code, platform_count: 4 }));
    for (const dir of ["down", "up"]) {
      for (let t0 = 300, n = 0; t0 < 1430; t0 += 8, n++) {
        const fast = n % 3 === 0, id = tid++;
        let path = stops.filter(s => !fast || s.fast);
        const total = path[path.length - 1].km * (fast ? 1.5 : 2.1);
        if (dir === "up") path = [...path].reverse();
        trains.push({ train_id: id, train_number: String(id), train_name: `${path[0].name} – ${path[path.length - 1].name}`,
          source: path[0].id, destination: path[path.length - 1].id, train_type: fast ? "FAST" : "SLOW",
          is_ac: n % 12 === 5, is_ladies_special: n % 40 === 7, cars: n % 5 === 0 ? 15 : 12 });
        path.forEach((s, i) => {
          const off = Math.round(dir === "down" ? s.km * (fast ? 1.5 : 2.1) : total - s.km * (fast ? 1.5 : 2.1));
          const last = i === path.length - 1;
          schedules.push({ train_id: id, station_id: s.id, arrival_time: t0 + off, departure_time: t0 + off + (i === 0 || last ? 0 : 1),
            platform_number: (dir === "down" ? 1 : 2) + (fast ? 2 : 0), halt_sequence: i + 1, distance_km: Math.abs(s.km - path[0].km) });
        });
      }
    }
  }
  return { stations, trains, schedules, demo: true };
}

const toMin = t => {                       // "23:45" | "00:10+1" | 1425  ->  minutes
  if (typeof t === "number") return t;
  const next = String(t).endsWith("+1"), [h, m] = String(t).replace("+1", "").split(":").map(Number);
  return h * 60 + m + (next ? 1440 : 0);
};

/* ============ 2. JSON PARSING / INDEXING ============ */
let DB = { stations: new Map(), trains: new Map(), stops: new Map(), byName: new Map(), demo: false };

function loadData(json) {
  if (!json || !Array.isArray(json.stations) || !Array.isArray(json.trains) || !Array.isArray(json.schedules))
    throw new Error("JSON must contain stations, trains and schedules arrays.");
  const db = { stations: new Map(), trains: new Map(), stops: new Map(), byName: new Map(), demo: !!json.demo };
  json.stations.forEach(s => {
    db.stations.set(s.station_id, s);
    db.byName.set(s.station_name.toLowerCase(), s.station_id);
    db.byName.set(String(s.station_code).toLowerCase(), s.station_id);
  });
  json.trains.forEach(t => db.trains.set(t.train_id, t));
  json.schedules.forEach(r => {
    if (!db.stops.has(r.train_id)) db.stops.set(r.train_id, []);
    db.stops.get(r.train_id).push({ sid: r.station_id, arr: toMin(r.arrival_time), dep: toMin(r.departure_time),
      pf: r.platform_number, seq: r.halt_sequence, km: r.distance_km });
  });
  db.stops.forEach(list => list.sort((a, b) => a.seq - b.seq));
  DB = db;
  const opts = [...db.stations.values()].sort((a, b) => a.station_name.localeCompare(b.station_name));
  $("#stationList").innerHTML = opts.map(s => `<option value="${esc(s.station_name)}">${esc(s.station_code)}</option>`).join("");
  const lines = [...new Set(opts.map(s => s.line_type))];
  $("#boardLine").innerHTML = `<option value="all">All lines</option>` + lines.map(l => `<option value="${l}">${lineName(l)}</option>`).join("");
  const b = $("#banner");
  b.hidden = !db.demo;
  b.textContent = "Demo timetable – times are illustrative. Use “Load JSON” to load your real Mumbai data.";
}

/* ============ 3. HELPERS ============ */
const $ = (q, el = document) => el.querySelector(q);
const esc = s => String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const lineName = l => ({ WESTERN: "Western", CENTRAL: "Central", HARBOUR: "Harbour", TRANS_HARBOUR: "Trans-Harbour" }[l] || l);
const lineVar = l => `var(--${String(l).toLowerCase()})`;
const nowMin = () => { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); };
const fmt = m => { const h = Math.floor(m / 60) % 24, mm = String(m % 60).padStart(2, "0"); return `${h % 12 || 12}:${mm} ${h < 12 ? "AM" : "PM"}`; };
const stationId = txt => DB.byName.get(String(txt).trim().toLowerCase());
const trainLine = t => DB.stations.get(t.source)?.line_type;
const store = {
  get: (k, d) => { try { return JSON.parse(localStorage.getItem(k)) ?? d; } catch { return d; } },
  set: (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* storage full / blocked */ } },
};
function rush(dep) {  // time-of-day baseline; swap for crowdsourced data later
  const m = dep % 1440;
  if ((m >= 480 && m <= 660) || (m >= 1050 && m <= 1230)) return ["high", "High rush"];
  if ((m >= 420 && m < 480) || (m > 660 && m <= 720) || (m > 1230 && m <= 1290)) return ["moderate", "Moderate rush"];
  return ["low", "Low rush"];
}
const eta = d => d <= 0 ? "Arriving now" : d <= 5 ? `Arriving in ${d} min` : `Next in ${d} min`;

/* ============ 4. SEARCH ============ */
const state = { filters: new Set(), when: "now" };

function search(from, to, after, f = state.filters) {
  const out = [];
  for (const [id, t] of DB.trains) {
    if (f.has("fast") && t.train_type !== "FAST") continue;
    if (f.has("ac") && !t.is_ac) continue;
    if (f.has("ladies") && !t.is_ladies_special) continue;
    const st = DB.stops.get(id) || [], i = st.findIndex(s => s.sid === from), j = st.findIndex(s => s.sid === to);
    if (i < 0 || j <= i || st[i].dep < after) continue;
    if (f.has("peak") && !((st[i].dep >= 480 && st[i].dep <= 660) || (st[i].dep >= 1020 && st[i].dep <= 1260))) continue;
    out.push({ t, dep: st[i].dep, arr: st[j].arr, pf: st[i].pf, from, to });
  }
  return out.sort((a, b) => a.dep - b.dep);
}

function connecting(from, to, after) {       // one change, >= 3 min buffer
  const reach = new Set();
  for (const st of DB.stops.values()) {
    const i = st.findIndex(s => s.sid === from);
    if (i >= 0) st.slice(i + 1).forEach(s => reach.add(s.sid));
  }
  const best = [];
  for (const x of reach) {
    if (x === to) continue;
    const a = search(from, x, after, new Set())[0];
    const b = a && search(x, to, a.arr + 3, new Set())[0];
    if (b) best.push({ a, x, b });
  }
  return best.sort((p, q) => p.b.arr - q.b.arr).slice(0, 3);
}

/* ============ 5. RENDER ============ */
function trainCard(r, showLive) {
  const t = r.t, lc = lineVar(trainLine(t)), [rc, rl] = rush(r.dep), now = nowMin();
  const live = showLive && r.dep >= now ? `<div class="live">${eta(r.dep - now)}</div>` : "";
  return `<article class="card train" style="--lc:${lc}" data-id="${t.train_id}" data-from="${r.from}" data-to="${r.to}">
    <div class="times"><span class="time">${fmt(r.dep)}</span><span class="dur">${r.arr - r.dep} min</span><span class="time">${fmt(r.arr)}</span></div>
    ${live}
    <div class="badges">
      <span class="b ${t.train_type === "FAST" ? "fast" : "slow"}">${t.train_type === "FAST" ? "F · Fast" : "S · Slow"}</span>
      ${t.is_ac ? `<span class="b ac">AC</span>` : `<span class="b plain">Non-AC</span>`}
      ${t.is_ladies_special ? `<span class="b ladies">Ladies special</span>` : ""}
      <span class="b plain">${t.cars}-car</span>
      ${r.pf != null ? `<span class="b plain">Platform ${r.pf}</span>` : ""}
      <span class="b ${rc}">${rl}</span>
    </div>
    <ol class="timeline" hidden></ol>
  </article>`;
}

function timeline(card) {
  const id = +card.dataset.id, st = DB.stops.get(id) || [], now = nowMin();
  const nextIdx = st.findIndex(s => s.dep >= now);
  return st.map((s, i) => {
    const name = DB.stations.get(s.sid)?.station_name ?? s.sid;
    const cls = [s.dep < now ? "past" : "", i === nextIdx ? "next" : "", s.sid == card.dataset.from || s.sid == card.dataset.to ? "mark" : ""].join(" ");
    return `<li class="${cls}"><span>${esc(name)}${i === nextIdx ? " · next" : ""}</span>
      <span class="meta">${fmt(s.arr)}${s.pf != null ? ` · PF ${s.pf}` : ""}${s.km != null ? ` · ${s.km.toFixed(1)} km` : ""}</span></li>`;
  }).join("");
}

function renderResults() {
  const box = $("#results"), from = stationId($("#from").value), to = stationId($("#to").value);
  if (!from || !to) { box.innerHTML = `<p class="empty">Choose a From and To station to see trains.</p>`; return; }
  if (from === to) { box.innerHTML = `<p class="empty">From and To are the same station.</p>`; return; }
  const w = $("#when").value, after = w === "now" ? nowMin() : 0;
  let list = search(from, to, after);
  if (w === "first") list = list.slice(0, 1);
  if (w === "last") list = list.slice(-1);
  if (list.length) { box.innerHTML = list.map(r => trainCard(r, w === "now")).join(""); return; }
  const alt = connecting(from, to, after);
  box.innerHTML = `<p class="empty">No direct train ${w === "now" ? "for the rest of today" : "found"}.</p>` +
    alt.map(c => `<div class="card suggest">Change at <b>${esc(DB.stations.get(c.x).station_name)}</b><br>
      ${fmt(c.a.dep)} → ${fmt(c.a.arr)}, then ${fmt(c.b.dep)} → ${fmt(c.b.arr)} (${c.b.arr - c.a.dep} min total)</div>`).join("");
}

function renderBoard() {
  const sid = stationId($("#boardStation").value), box = $("#boardList");
  if (!sid) { box.innerHTML = `<p class="empty">Choose a station to see upcoming trains.</p>`; return; }
  const dir = $("#boardDir").value, line = $("#boardLine").value, now = nowMin(), rows = [];
  for (const [id, st] of DB.stops) {
    const s = st.find(x => x.sid === sid), t = DB.trains.get(id);
    if (!s || s.dep < now || s === st[st.length - 1]) continue;      // skip trains terminating here
    const d = t.source < t.destination ? "down" : "up";              // demo ids run city -> suburb; add a `direction` field to your JSON if this rule doesn't hold
    if ((dir !== "all" && d !== dir) || (line !== "all" && trainLine(t) !== line)) continue;
    rows.push({ t, s });
  }
  rows.sort((a, b) => a.s.dep - b.s.dep);
  box.innerHTML = rows.slice(0, 10).map(({ t, s }) => `
    <div class="card board-row" style="--lc:${lineVar(trainLine(t))}">
      <div><b>To ${esc(DB.stations.get(t.destination).station_name)}</b><br>
        <span class="b ${t.train_type === "FAST" ? "fast" : "slow"}">${t.train_type === "FAST" ? "F" : "S"}</span>
        ${t.is_ac ? `<span class="b ac">AC</span>` : ""} <span class="b plain">${t.cars}-car</span></div>
      <div class="when">${eta(s.dep - now)}<small>${fmt(s.dep)}${s.pf != null ? ` · PF ${s.pf}` : ""}</small></div>
    </div>`).join("") || `<p class="empty">No more trains today for this filter.</p>`;
}

function renderChips() {
  const favs = store.get("favs", []), rec = store.get("recents", []);
  const mk = (arr, pre) => arr.map(r => `<button class="chip" data-a="${esc(r[0])}" data-b="${esc(r[1])}">${pre}${esc(r[0])} → ${esc(r[1])}</button>`).join("");
  $("#favs").innerHTML = mk(favs, "★ "); $("#recents").innerHTML = mk(rec.slice(0, 4), "");
}

/* ============ 6. EVENTS ============ */
function pushRecent() {
  const a = $("#from").value.trim(), b = $("#to").value.trim();
  if (!stationId(a) || !stationId(b)) return;
  store.set("recents", [[a, b], ...store.get("recents", []).filter(r => !(r[0] === a && r[1] === b))].slice(0, 8));
  renderChips();
}
["from", "to"].forEach(id => $("#" + id).addEventListener("change", () => { renderResults(); pushRecent(); }));
$("#when").addEventListener("change", renderResults);
$("#swap").addEventListener("click", () => { const f = $("#from"); [f.value, $("#to").value] = [$("#to").value, f.value]; renderResults(); });
$("#filters").addEventListener("click", e => {
  const c = e.target.closest(".chip"); if (!c) return;
  c.classList.toggle("on"); c.classList.contains("on") ? state.filters.add(c.dataset.f) : state.filters.delete(c.dataset.f);
  renderResults();
});
$("#saveFav").addEventListener("click", () => {
  const a = $("#from").value.trim(), b = $("#to").value.trim();
  if (!stationId(a) || !stationId(b)) return;
  store.set("favs", [[a, b], ...store.get("favs", []).filter(r => !(r[0] === a && r[1] === b))].slice(0, 6)); renderChips();
});
document.addEventListener("click", e => {
  const chip = e.target.closest("#favs .chip, #recents .chip");
  if (chip) { $("#from").value = chip.dataset.a; $("#to").value = chip.dataset.b; renderResults(); return; }
  const card = e.target.closest(".train");
  if (card) { const ol = $(".timeline", card); if (ol.hidden) ol.innerHTML = timeline(card); ol.hidden = !ol.hidden; }
});
document.querySelectorAll(".tab").forEach(tab => tab.addEventListener("click", () => {
  document.querySelectorAll(".tab").forEach(t => t.classList.toggle("on", t === tab));
  $("#route").hidden = tab.dataset.tab !== "route"; $("#board").hidden = tab.dataset.tab !== "board";
  tab.dataset.tab === "board" ? renderBoard() : renderResults();
}));
["boardStation", "boardDir", "boardLine"].forEach(id => $("#" + id).addEventListener("change", renderBoard));
$("#themeBtn").addEventListener("click", () => {
  const dark = document.documentElement.dataset.theme !== "dark";
  document.documentElement.dataset.theme = dark ? "dark" : "light"; $("#themeBtn").textContent = dark ? "Light" : "Dark"; store.set("theme", dark);
});
$("#jsonFile").addEventListener("change", e => {
  const file = e.target.files[0]; if (!file) return;
  const rd = new FileReader();
  rd.onload = () => {
    try { const j = JSON.parse(rd.result); loadData(j); store.set("userData", j); renderResults(); renderBoard(); }
    catch (err) { alert("Could not load file: " + err.message); }
  };
  rd.readAsText(file);
});

/* ============ 7. START ============ */
if (store.get("theme", window.matchMedia("(prefers-color-scheme: dark)").matches)) { document.documentElement.dataset.theme = "dark"; $("#themeBtn").textContent = "Light"; }
try { loadData(store.get("userData", null) || buildDemo()); } catch { loadData(buildDemo()); }   // offline: last loaded JSON is remembered
renderChips(); renderResults(); renderBoard();
setInterval(() => { renderBoard(); if ($("#when").value === "now" && !$("#results .timeline:not([hidden])")) renderResults(); }, 30000);  // live countdown refresh
