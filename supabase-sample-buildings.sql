-- Sample Buildings Data for HomeConnect App
-- Insert sample apartments and societies for testing

INSERT INTO buildings (name, category, address, created_at, updated_at) VALUES
-- Sample Apartments
('Sunrise Apartments', 'apartment', '123 Main Street, City Center', NOW(), NOW()),
('Green Valley Apartments', 'apartment', '456 Oak Avenue, Downtown', NOW(), NOW()),
('Royal Heights Apartments', 'apartment', '789 Pine Road, Uptown', NOW(), NOW()),
('Blue Sky Apartments', 'apartment', '321 Elm Street, Midtown', NOW(), NOW()),
('Golden Gate Apartments', 'apartment', '654 Maple Drive, Westside', NOW(), NOW()),

-- Sample Societies  
('Palm Grove Society', 'society', '111 Palm Street, Garden District', NOW(), NOW()),
('Rose Garden Society', 'society', '222 Rose Avenue, Flower Town', NOW(), NOW()),
('Emerald Park Society', 'society', '333 Park Lane, Green Hills', NOW(), NOW()),
('Diamond Heights Society', 'society', '444 Diamond Road, Heights Area', NOW(), NOW()),
('Silver Springs Society', 'society', '555 Spring Street, Riverside', NOW(), NOW()),

-- Additional Mixed Options
('Metro Plaza Apartments', 'apartment', '777 Metro Boulevard, Business District', NOW(), NOW()),
('Harmony Heights Society', 'society', '888 Harmony Lane, Peaceful Valley', NOW(), NOW()),
('Sunshine Towers Apartments', 'apartment', '999 Sunshine Avenue, Sunny Side', NOW(), NOW()),
('Moonlight Gardens Society', 'society', '101 Moonlight Drive, Quiet Zone', NOW(), NOW()),
('Crystal Bay Apartments', 'apartment', '202 Crystal Street, Bay Area', NOW(), NOW());

-- Verify the data was inserted
SELECT 
    name, 
    category, 
    address,
    created_at
FROM buildings 
ORDER BY category, name; 