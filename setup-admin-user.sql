-- Setup Admin User for HomeConnect App
-- Run this script in your Supabase SQL Editor

-- First, check if admin user already exists
SELECT 
    id,
    email,
    role,
    is_approved,
    created_at
FROM users 
WHERE email = 'admin@homeconnect.com' OR role = 'admin';

-- If no admin user exists, you need to:
-- 1. Create the user through Supabase Auth (signup)
-- 2. Then update their role to admin

-- After creating the user through signup, run this to make them admin:
-- REPLACE 'USER_AUTH_ID_HERE' with the actual auth_user_id from the signup

-- UPDATE users 
-- SET 
--     role = 'admin',
--     is_approved = true,
--     approved_at = NOW()
-- WHERE auth_user_id = 'USER_AUTH_ID_HERE';

-- Alternative: If you want to create admin directly (advanced)
-- You'll need to get the auth user ID first from Supabase Auth dashboard

-- Check all users to see current state
SELECT 
    id,
    auth_user_id,
    email,
    first_name,
    last_name,
    role,
    is_approved,
    created_at
FROM users 
ORDER BY created_at DESC;

-- Verify admin user setup
SELECT 
    'Admin user check' as check_type,
    COUNT(*) as admin_count
FROM users 
WHERE role = 'admin' AND is_approved = true; 