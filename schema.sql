-- =========================
-- Extensions
-- =========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- Enums
-- =========================
DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('active', 'locked', 'restricted');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE session_status AS ENUM ('active', 'expired', 'revoked', 'suspicious');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =========================
-- Users
-- =========================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    password_hash TEXT NOT NULL,

    status user_status NOT NULL DEFAULT 'active',

    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    risk_flags JSONB NOT NULL DEFAULT '{}'::jsonb,

    account_balance BIGINT NOT NULL DEFAULT 0 CHECK (account_balance >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
-- Sessions
-- =========================
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    session_token_hash TEXT NOT NULL UNIQUE,

    status session_status NOT NULL DEFAULT 'active',

    ip_address INET NOT NULL,
    anomaly_flag BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,

    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (expires_at > created_at)
);

-- =========================
-- Permissions
-- =========================
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE
);

-- =========================
-- Roles
-- =========================
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- =========================
-- User Roles
-- =========================
CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- =========================
-- Financial Ledger (Invariant: no money creation/destruction)
-- =========================
CREATE TABLE IF NOT EXISTS ledger_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    from_user_id UUID REFERENCES users(id),
    to_user_id UUID REFERENCES users(id),

    amount BIGINT NOT NULL CHECK (amount > 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (
        (from_user_id IS NOT NULL AND to_user_id IS NOT NULL)
        OR
        (from_user_id IS NULL AND to_user_id IS NOT NULL)
        OR
        (from_user_id IS NOT NULL AND to_user_id IS NULL)
    )
);
