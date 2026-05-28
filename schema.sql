-- ═══════════════════════════════════════════════════════
-- CHECKME O2 · Schéma PostgreSQL complet
-- Projet : Matteo-Duc's Project (Supabase)
-- ═══════════════════════════════════════════════════════

-- 1. PROFIL ATHLÈTE
create table if not exists athlete_profile (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  nom text,
  prenom text,
  date_naissance date,
  poids_kg numeric(5,1),
  taille_cm integer,
  discipline text default 'Marche athlétique',
  niveau text default 'Élite',
  fc_repos_habituelle integer,
  spo2_repos_habituelle numeric(4,1),
  altitude_domicile_m integer default 0,
  coach_email text,
  notes text
);

-- 2. SESSIONS NOCTURNES (stats résumées par nuit)
create table if not exists sessions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  date_nuit date not null,
  filename text,
  duree_heures numeric(4,2),
  nb_points integer,
  intervalle_s integer default 2,

  -- SpO2
  spo2_moyenne numeric(4,1),
  spo2_minimale numeric(4,1),
  spo2_maximale numeric(4,1),
  temps_sous_90_pct numeric(5,2),
  temps_sous_88_pct numeric(5,2),
  odi4 numeric(6,2),
  odi3 numeric(6,2),

  -- Fréquence cardiaque
  fc_minimale integer,
  fc_moyenne numeric(5,1),
  fc_maximale integer,

  -- Score & interprétation
  score_recuperation integer,
  score_spo2 integer,
  score_fc integer,
  score_t90 integer,
  score_odi integer,
  interpretation text,

  -- Contexte athlète
  ressenti_nuit integer check (ressenti_nuit between 1 and 5),
  qualite_sommeil integer check (qualite_sommeil between 1 and 5),
  charge_entrainement_veille integer check (charge_entrainement_veille between 1 and 10),
  note_contexte text,
  en_stage boolean default false,
  altitude_nuit_m integer default 0,

  -- Nb événements
  nb_desaturations integer default 0
);

-- 3. DONNÉES BRUTES (courbes seconde par seconde)
create table if not exists raw_data (
  id bigserial primary key,
  session_id uuid references sessions(id) on delete cascade,
  t integer not null,          -- offset en secondes depuis début session
  time_label text,             -- ex: "00:04:38 May 03 2025"
  spo2 smallint,
  fc smallint,
  mouvement smallint
);

-- Index pour requêtes rapides
create index if not exists raw_data_session_idx on raw_data(session_id);
create index if not exists sessions_date_idx on sessions(date_nuit desc);

-- 4. ENTRAÎNEMENTS (futur : Polar / Strava / manuel)
create table if not exists training_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  date_entrainement date not null,
  source text default 'manuel',    -- 'polar', 'strava', 'garmin', 'manuel'
  type_seance text,                -- 'endurance', 'fractionné', 'compétition', 'récup'
  duree_min integer,
  distance_km numeric(6,2),
  fc_moyenne integer,
  fc_max integer,
  vitesse_moy_kmh numeric(5,2),
  charge_rpe integer check (charge_rpe between 1 and 10),
  denivele_m integer,
  note text,
  data_raw jsonb                   -- toutes les données source brutes
);

-- 5. PARTAGES COACH (liens temporaires)
create table if not exists coach_shares (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  token text unique default encode(gen_random_bytes(16), 'hex'),
  actif boolean default true,
  expires_at timestamptz default (now() + interval '1 year'),
  coach_email text,
  nom_coach text
);

-- ── SÉCURITÉ : Row Level Security ──────────────────────
alter table athlete_profile enable row level security;
alter table sessions enable row level security;
alter table raw_data enable row level security;
alter table training_logs enable row level security;
alter table coach_shares enable row level security;

-- Politique : tout le monde peut lire/écrire (app sans auth pour l'instant)
-- On renforcera avec l'auth email plus tard
create policy "allow_all_athlete_profile" on athlete_profile for all using (true) with check (true);
create policy "allow_all_sessions" on sessions for all using (true) with check (true);
create policy "allow_all_raw_data" on raw_data for all using (true) with check (true);
create policy "allow_all_training" on training_logs for all using (true) with check (true);
create policy "allow_all_shares" on coach_shares for all using (true) with check (true);
