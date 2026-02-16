-- Seed users for Concurrency Tests
-- racers (1-10), overfill (1-5), feeder (1-3), liq_racer (1-10), atomic_user

INSERT OR IGNORE INTO users (id, name, email, deposit_credits, winning_credits) VALUES 
('racer_1', 'Racer 1', 'r1@test.com', 1000, 0),
('racer_2', 'Racer 2', 'r2@test.com', 1000, 0),
('racer_3', 'Racer 3', 'r3@test.com', 1000, 0),
('racer_4', 'Racer 4', 'r4@test.com', 1000, 0),
('racer_5', 'Racer 5', 'r5@test.com', 1000, 0),
('racer_6', 'Racer 6', 'r6@test.com', 1000, 0),
('racer_7', 'Racer 7', 'r7@test.com', 1000, 0),
('racer_8', 'Racer 8', 'r8@test.com', 1000, 0),
('racer_9', 'Racer 9', 'r9@test.com', 1000, 0),
('racer_10', 'Racer 10', 'r10@test.com', 1000, 0),

('overfill_1', 'Overfill 1', 'o1@test.com', 1000, 0),
('overfill_2', 'Overfill 2', 'o2@test.com', 1000, 0),
('overfill_3', 'Overfill 3', 'o3@test.com', 1000, 0),
('overfill_4', 'Overfill 4', 'o4@test.com', 1000, 0),
('overfill_5', 'Overfill 5', 'o5@test.com', 1000, 0),

('feeder_1', 'Feeder 1', 'f1@test.com', 1000, 0),
('feeder_2', 'Feeder 2', 'f2@test.com', 1000, 0),
('feeder_3', 'Feeder 3', 'f3@test.com', 1000, 0),

('liq_racer_1', 'Liq Racer 1', 'lr1@test.com', 1000, 0),
('liq_racer_2', 'Liq Racer 2', 'lr2@test.com', 1000, 0),
('liq_racer_3', 'Liq Racer 3', 'lr3@test.com', 1000, 0),
('liq_racer_4', 'Liq Racer 4', 'lr4@test.com', 1000, 0),
('liq_racer_5', 'Liq Racer 5', 'lr5@test.com', 1000, 0),
('liq_racer_6', 'Liq Racer 6', 'lr6@test.com', 1000, 0),
('liq_racer_7', 'Liq Racer 7', 'lr7@test.com', 1000, 0),
('liq_racer_8', 'Liq Racer 8', 'lr8@test.com', 1000, 0),
('liq_racer_9', 'Liq Racer 9', 'lr9@test.com', 1000, 0),
('liq_racer_10', 'Liq Racer 10', 'lr10@test.com', 1000, 0),

('atomic_user', 'Atomic User', 'atomic@test.com', 10000, 0);
