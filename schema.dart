/// SQLite schema for the spec JSON (stations / trains / schedules).
const schemaSql = <String>[
  '''CREATE TABLE stations(
    station_id INTEGER PRIMARY KEY, station_name TEXT NOT NULL,
    line_type TEXT NOT NULL,            -- WESTERN|CENTRAL|HARBOUR|TRANS_HARBOUR
    station_code TEXT UNIQUE NOT NULL, platform_count INTEGER DEFAULT 2)''',
  '''CREATE TABLE trains(
    train_id INTEGER PRIMARY KEY, train_number TEXT, train_name TEXT,
    source INTEGER REFERENCES stations(station_id),
    destination INTEGER REFERENCES stations(station_id),
    train_type TEXT CHECK(train_type IN('FAST','SLOW')),
    is_ac INTEGER DEFAULT 0, is_ladies_special INTEGER DEFAULT 0,
    cars INTEGER CHECK(cars IN(12,15)))''',
  '''CREATE TABLE schedules(
    train_id INTEGER REFERENCES trains(train_id),
    station_id INTEGER REFERENCES stations(station_id),
    arrival_time INTEGER, departure_time INTEGER,   -- minutes since midnight
    platform_number INTEGER, halt_sequence INTEGER NOT NULL,
    distance_km REAL,                               -- optional, cumulative from source
    PRIMARY KEY(train_id, halt_sequence))''',
  'CREATE INDEX ix_sched_station ON schedules(station_id, departure_time)',
  'CREATE INDEX ix_sched_train ON schedules(train_id, halt_sequence)',
  'CREATE TABLE meta(k TEXT PRIMARY KEY, v TEXT)',
];
