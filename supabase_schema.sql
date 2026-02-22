-- ═══════════════════════════════════════════════════════════════════
-- MONCOMPTOIR PRO — SCHÉMA SUPABASE COMPLET
-- Collez ce SQL dans : Supabase Dashboard > SQL Editor > New Query
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
-- 1. TABLE PROFILES (informations utilisateurs)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email               TEXT NOT NULL,
  name                TEXT,
  sector              TEXT,
  city                TEXT,
  role                TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  subscription_status TEXT NOT NULL DEFAULT 'trial' CHECK (subscription_status IN ('trial','active','pending','inactive')),
  trial_end           TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  subscription_expiry TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────────────
-- 2. TABLE SALES (ventes)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  client_name TEXT,
  description TEXT,
  category    TEXT DEFAULT 'Autre',
  amount      NUMERIC(12,0) NOT NULL CHECK (amount >= 0),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────────────
-- 3. TABLE EXPENSES (charges et dépenses)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expenses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  category    TEXT DEFAULT 'Autre',
  description TEXT,
  amount      NUMERIC(12,0) NOT NULL CHECK (amount >= 0),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────────────
-- 4. TABLE PRODUCTS (articles / stock)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  sku          TEXT,
  category     TEXT DEFAULT 'Autre',
  quantity     INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  min_quantity INTEGER NOT NULL DEFAULT 5 CHECK (min_quantity >= 0),
  buy_price    NUMERIC(12,0) NOT NULL DEFAULT 0 CHECK (buy_price >= 0),
  sell_price   NUMERIC(12,0) NOT NULL DEFAULT 0 CHECK (sell_price >= 0),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────────────
-- 5. TABLE CLIENTS (portefeuille clients)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clients (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  company     TEXT,
  phone       TEXT,
  city        TEXT DEFAULT 'Douala',
  total_spent NUMERIC(12,0) DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────────────
-- 6. TABLE SUBSCRIPTIONS (demandes d'abonnement)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan               TEXT NOT NULL CHECK (plan IN ('monthly','yearly')),
  amount             NUMERIC(12,0) NOT NULL,
  transaction_number TEXT,
  proof_path         TEXT,
  status             TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS) — Isolation complète par utilisateur
-- ═══════════════════════════════════════════════════════════════════

-- Activer RLS sur toutes les tables
ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales         ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses      ENABLE ROW LEVEL SECURITY;
ALTER TABLE products      ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients       ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ── PROFILES ──
CREATE POLICY "Utilisateur voit son profil"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Utilisateur modifie son profil"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Création de profil à l'inscription"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Admin voit tous les profils
CREATE POLICY "Admin voit tous les profils"
  ON profiles FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin modifie tous les profils"
  ON profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ── SALES ──
CREATE POLICY "Ventes: lecture utilisateur"
  ON sales FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Ventes: insertion utilisateur"
  ON sales FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Ventes: modification utilisateur"
  ON sales FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Ventes: suppression utilisateur"
  ON sales FOR DELETE USING (auth.uid() = user_id);

-- ── EXPENSES ──
CREATE POLICY "Charges: lecture utilisateur"
  ON expenses FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Charges: insertion utilisateur"
  ON expenses FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Charges: modification utilisateur"
  ON expenses FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Charges: suppression utilisateur"
  ON expenses FOR DELETE USING (auth.uid() = user_id);

-- ── PRODUCTS ──
CREATE POLICY "Stock: lecture utilisateur"
  ON products FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Stock: insertion utilisateur"
  ON products FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Stock: modification utilisateur"
  ON products FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Stock: suppression utilisateur"
  ON products FOR DELETE USING (auth.uid() = user_id);

-- ── CLIENTS ──
CREATE POLICY "Clients: lecture utilisateur"
  ON clients FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Clients: insertion utilisateur"
  ON clients FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Clients: modification utilisateur"
  ON clients FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Clients: suppression utilisateur"
  ON clients FOR DELETE USING (auth.uid() = user_id);

-- ── SUBSCRIPTIONS ──
CREATE POLICY "Abonnements: lecture utilisateur"
  ON subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Abonnements: insertion utilisateur"
  ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin voit et modifie tous les abonnements
CREATE POLICY "Admin: lecture tous abonnements"
  ON subscriptions FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin: modification tous abonnements"
  ON subscriptions FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ═══════════════════════════════════════════════════════════════════
-- INDEXES — Performance
-- ═══════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_sales_user_id     ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_date        ON sales(date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id  ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date     ON expenses(date DESC);
CREATE INDEX IF NOT EXISTS idx_products_user_id  ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_user_id   ON clients(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_user_id      ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_status       ON subscriptions(status);

-- ═══════════════════════════════════════════════════════════════════
-- TRIGGER — updated_at automatique
-- ═══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_sales_updated
  BEFORE UPDATE ON sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_expenses_updated
  BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_products_updated
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_clients_updated
  BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_subs_updated
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════════════
-- STORAGE — Bucket pour les preuves de paiement
-- (Exécutez ceci dans Supabase Dashboard > Storage > New Bucket)
-- ═══════════════════════════════════════════════════════════════════
-- Bucket name: subscription-proofs
-- Public: false (privé)
-- Allowed MIME types: image/png, image/jpeg, image/webp
-- Max file size: 5 MB

-- ═══════════════════════════════════════════════════════════════════
-- CRÉER LE COMPTE ADMIN
-- Remplacez 'admin@votreentreprise.cm' par votre email admin
-- Exécutez APRÈS avoir créé le compte via l'interface
-- ═══════════════════════════════════════════════════════════════════
-- UPDATE profiles SET role = 'admin' WHERE email = 'admin@votreentreprise.cm';
