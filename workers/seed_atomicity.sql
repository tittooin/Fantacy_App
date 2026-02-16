-- Setup users for Wallet Atomicity Tests
-- atomic_poor: 25 credits (Enough for 2 x 10)
-- atomic_rollback: 100 credits (Expect 90 after 1 success + 2 rollbacks)

INSERT OR REPLACE INTO users (id, name, email, deposit_credits, winning_credits) VALUES 
('atomic_poor', 'Poor Atomic', 'poor@test.com', 25, 0),
('atomic_rollback', 'Rollback Atomic', 'rollback@test.com', 100, 0);
