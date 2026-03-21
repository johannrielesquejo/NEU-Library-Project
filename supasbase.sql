
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS admin_profiles CASCADE;
DROP TABLE IF EXISTS visit_logs CASCADE;
DROP TABLE IF EXISTS visitors CASCADE;
DROP TABLE IF EXISTS colleges CASCADE;
DROP TYPE IF EXISTS visit_purpose CASCADE;
DROP TYPE IF EXISTS login_method CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;


-- ============================================================
-- NEU Library Visitor Log — Supabase SQL Schema (UPDATED)
-- New Era University · Philippines
-- ============================================================

-- 1. ENUM TYPES
CREATE TYPE visit_purpose AS ENUM (
  'Reading',
  'Research',
  'Studying',
  'Use of Computer'
);

CREATE TYPE login_method AS ENUM (
  'Email',
  'RFID'
);

-- 2. COLLEGES LOOKUP TABLE
CREATE TABLE colleges (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO colleges (name) VALUES
  ('College of Information and Computing Studies'),
  ('College of Business Administration'),
  ('College of Education'),
  ('College of Arts and Sciences'),
  ('College of Engineering and Architecture'),
  ('College of Nursing and Allied Health Sciences'),
  ('College of Criminal Justice Education'),
  ('College of Tourism and Hospitality Management'),
  ('Graduate School');

-- 3. VISITORS TABLE
CREATE TABLE visitors (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT        UNIQUE,
  student_id    TEXT        UNIQUE,
  full_name     TEXT,
  college_id    INTEGER     REFERENCES colleges(id) ON DELETE SET NULL,
  is_blocked    BOOLEAN     NOT NULL DEFAULT FALSE,
  blocked_at    TIMESTAMPTZ,
  blocked_by    TEXT,
  block_reason  TEXT,
  is_employee   BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT visitor_has_identifier CHECK (email IS NOT NULL OR student_id IS NOT NULL)
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER visitors_updated_at
  BEFORE UPDATE ON visitors
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Indexes
CREATE INDEX idx_visitors_email      ON visitors (email);
CREATE INDEX idx_visitors_student_id ON visitors (student_id);
CREATE INDEX idx_visitors_college    ON visitors (college_id);
CREATE INDEX idx_visitors_blocked    ON visitors (is_blocked);

-- 4. VISIT_LOGS TABLE
CREATE TABLE visit_logs (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id    UUID          REFERENCES visitors(id) ON DELETE CASCADE,
  college_id    INTEGER       REFERENCES colleges(id) ON DELETE SET NULL,
  purpose       visit_purpose NOT NULL,
  login_method  login_method  NOT NULL,
  visited_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Indexes for dashboard queries
CREATE INDEX idx_visit_logs_visitor    ON visit_logs (visitor_id);
CREATE INDEX idx_visit_logs_visited_at ON visit_logs (visited_at DESC);
CREATE INDEX idx_visit_logs_college    ON visit_logs (college_id);
CREATE INDEX idx_visit_logs_purpose    ON visit_logs (purpose);

-- 5. ADMIN TABLE (simplified)
CREATE TABLE admins (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT        UNIQUE NOT NULL,
  full_name     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert sample admin
INSERT INTO admins (email, full_name) VALUES
  ('admin@neu.edu.ph', 'Library Administrator'),
  ('librarian@neu.edu.ph', 'Head Librarian');

-- 6. USEFUL VIEWS
CREATE VIEW v_visit_logs AS
SELECT
  vl.id,
  vl.visited_at,
  vl.purpose,
  vl.login_method,
  v.email,
  v.student_id,
  v.full_name,
  v.is_blocked,
  v.is_employee,
  c.name AS college
FROM visit_logs vl
LEFT JOIN visitors v  ON v.id = vl.visitor_id
LEFT JOIN colleges c  ON c.id = vl.college_id
ORDER BY vl.visited_at DESC;

CREATE VIEW v_visitor_summary AS
SELECT
  v.id,
  v.email,
  v.student_id,
  v.full_name,
  v.is_blocked,
  v.is_employee,
  c.name   AS college,
  COUNT(vl.id)     AS total_visits,
  MAX(vl.visited_at) AS last_visit
FROM visitors v
LEFT JOIN colleges c    ON c.id = v.college_id
LEFT JOIN visit_logs vl ON vl.visitor_id = v.id
GROUP BY v.id, v.email, v.student_id, v.full_name, v.is_blocked, v.is_employee, c.name
ORDER BY last_visit DESC NULLS LAST;

-- 7. ROW-LEVEL SECURITY
ALTER TABLE visitors   ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE colleges   ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins     ENABLE ROW LEVEL SECURITY;

-- Colleges: public read
CREATE POLICY "Colleges are publicly readable"
  ON colleges FOR SELECT USING (true);

-- Visitors: anyone can register
CREATE POLICY "Anyone can register as visitor"
  ON visitors FOR INSERT WITH CHECK (true);

-- Visitors: anyone can read (for login verification)
CREATE POLICY "Visitors can read own record"
  ON visitors FOR SELECT USING (true);

-- Visit logs: anyone can insert
CREATE POLICY "Anyone can log a visit"
  ON visit_logs FOR INSERT WITH CHECK (true);

-- Admins: admins can read all visit logs
CREATE POLICY "Admins can read all visit logs"
  ON visit_logs FOR SELECT
  USING (auth.uid() IN (SELECT id FROM admins));

-- Admins: admins can update visitors
CREATE POLICY "Admins can update visitors"
  ON visitors FOR UPDATE
  USING (auth.uid() IN (SELECT id FROM admins));

-- Admins: admins can read all visitors
CREATE POLICY "Admins can read all visitors"
  ON visitors FOR SELECT
  USING (auth.uid() IN (SELECT id FROM admins));

-- Admins table: admins can read
CREATE POLICY "Admins can read admin list"
  ON admins FOR SELECT
  USING (true);

-- 8. HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION log_library_visit(
  p_identifier   TEXT,
  p_method       login_method,
  p_college_name TEXT,
  p_purpose      visit_purpose,
  p_is_employee  BOOLEAN DEFAULT FALSE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_visitor    visitors%ROWTYPE;
  v_college_id INTEGER;
  v_log_id     UUID;
BEGIN
  -- Get college
  SELECT id INTO v_college_id FROM colleges WHERE name = p_college_name;
  IF v_college_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Unknown college');
  END IF;

  -- Find visitor
  IF p_method = 'Email' THEN
    SELECT * INTO v_visitor FROM visitors WHERE email = p_identifier;
  ELSE
    SELECT * INTO v_visitor FROM visitors WHERE student_id = p_identifier;
  END IF;

  -- Auto-register if not found
  IF v_visitor.id IS NULL THEN
    IF p_method = 'Email' THEN
      INSERT INTO visitors (email, college_id, is_employee)
        VALUES (p_identifier, v_college_id, p_is_employee)
        RETURNING * INTO v_visitor;
    ELSE
      INSERT INTO visitors (student_id, college_id, is_employee)
        VALUES (p_identifier, v_college_id, p_is_employee)
        RETURNING * INTO v_visitor;
    END IF;
  END IF;

  -- Check if blocked
  IF v_visitor.is_blocked THEN
    RETURN json_build_object('success', false, 'error', 'blocked');
  END IF;

  -- Insert visit log
  INSERT INTO visit_logs (visitor_id, college_id, purpose, login_method)
    VALUES (v_visitor.id, v_college_id, p_purpose, p_method)
    RETURNING id INTO v_log_id;

  RETURN json_build_object(
    'success',    true,
    'visit_id',   v_log_id,
    'visitor_id', v_visitor.id,
    'visitor_data', json_build_object(
      'full_name', v_visitor.full_name,
      'email', v_visitor.email,
      'student_id', v_visitor.student_id,
      'college', p_college_name,
      'purpose', p_purpose,
      'is_employee', v_visitor.is_employee
    )
  );
END;
$$;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON colleges          TO anon, authenticated;
GRANT INSERT ON visitors          TO anon, authenticated;
GRANT SELECT ON visitors          TO anon, authenticated;
GRANT INSERT ON visit_logs        TO anon, authenticated;
GRANT SELECT ON v_visit_logs      TO authenticated;
GRANT SELECT ON v_visitor_summary TO authenticated;
GRANT EXECUTE ON FUNCTION log_library_visit TO anon, authenticated;