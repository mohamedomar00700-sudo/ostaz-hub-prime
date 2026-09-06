-- 1. Profiles (linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. User Roles
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('owner', 'admin', 'supervisor', 'teacher', 'student', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. Signup Invites
CREATE TABLE IF NOT EXISTS public.signup_invites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT CHECK (role IN ('owner', 'supervisor', 'teacher', 'student')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.signup_invites ENABLE ROW LEVEL SECURITY;

-- 4. Families
CREATE TABLE IF NOT EXISTS public.families (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    country TEXT,
    currency TEXT DEFAULT 'EGP',
    notes TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;

-- 5. Students
CREATE TABLE IF NOT EXISTS public.students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    country TEXT,
    currency TEXT DEFAULT 'EGP',
    rate NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'active',
    notes TEXT,
    family_id UUID REFERENCES public.families(id) ON DELETE SET NULL,
    stage TEXT,
    grade TEXT,
    curriculum_type TEXT,
    study_language TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- 6. Teachers
CREATE TABLE IF NOT EXISTS public.teachers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    subject TEXT,
    subject_key TEXT,
    rate_egp NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

-- 7. Recurring Lessons (Weekly Schedule)
CREATE TABLE IF NOT EXISTS public.recurring_lessons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE SET NULL, -- Null if group lesson
    subject TEXT NOT NULL,
    day_of_week INTEGER NOT NULL, -- 0-6 (Sunday-Saturday)
    lesson_time TEXT NOT NULL, -- e.g., '14:00'
    lesson_link TEXT,
    student_rate NUMERIC DEFAULT 0,
    student_currency TEXT DEFAULT 'EGP',
    teacher_rate_egp NUMERIC DEFAULT 0,
    duration_hours NUMERIC DEFAULT 1,
    pre_lesson_minutes NUMERIC DEFAULT 0,
    post_lesson_minutes NUMERIC DEFAULT 0,
    is_group BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.recurring_lessons ENABLE ROW LEVEL SECURITY;

-- 8. Lesson Students (For Group Lessons)
CREATE TABLE IF NOT EXISTS public.lesson_students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lesson_id UUID REFERENCES public.recurring_lessons(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    price_per_hour NUMERIC DEFAULT 0,
    currency TEXT DEFAULT 'EGP',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE (lesson_id, student_id)
);

ALTER TABLE public.lesson_students ENABLE ROW LEVEL SECURITY;

-- 9. Lesson Sessions (Completed Lessons log)
CREATE TABLE IF NOT EXISTS public.lesson_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recurring_lesson_id UUID REFERENCES public.recurring_lessons(id) ON DELETE CASCADE,
    duration_hours NUMERIC NOT NULL,
    session_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'completed', -- 'completed', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.lesson_sessions ENABLE ROW LEVEL SECURITY;

-- 10. Payments (Invoices payments log)
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.students(id) ON DELETE SET NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    recurring_lesson_id UUID REFERENCES public.recurring_lessons(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency TEXT DEFAULT 'EGP',
    amount_egp NUMERIC NOT NULL,
    period TEXT NOT NULL, -- e.g., 'March 2026'
    notes TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'paid', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 11. Family Invoices
CREATE TABLE IF NOT EXISTS public.family_invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    period TEXT NOT NULL, -- e.g., 'March 2026'
    currency TEXT DEFAULT 'EGP',
    total_amount NUMERIC NOT NULL,
    paid_amount NUMERIC DEFAULT 0,
    notes TEXT,
    status TEXT DEFAULT 'unpaid', -- 'unpaid', 'paid', 'partially_paid'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE (family_id, period)
);

ALTER TABLE public.family_invoices ENABLE ROW LEVEL SECURITY;

-- 12. Issues (Tickets)
CREATE TABLE IF NOT EXISTS public.issues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT NOT NULL, -- 'tech', 'delay', 'behavior', etc.
    lesson_id UUID REFERENCES public.recurring_lessons(id) ON DELETE SET NULL,
    teacher_name TEXT,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'closed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;

-- 13. Teacher Evaluations
CREATE TABLE IF NOT EXISTS public.teacher_evaluations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_name TEXT NOT NULL,
    punctuality NUMERIC DEFAULT 5,
    teaching_quality NUMERIC DEFAULT 5,
    communication NUMERIC DEFAULT 5,
    cooperation NUMERIC DEFAULT 5,
    average NUMERIC DEFAULT 5,
    week_of TEXT NOT NULL, -- e.g. '2026-W11'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.teacher_evaluations ENABLE ROW LEVEL SECURITY;

-- 14. Custom Notifications / Reminders
CREATE TABLE IF NOT EXISTS public.custom_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT,
    notification_time TEXT NOT NULL, -- e.g., '09:00'
    repeat_type TEXT DEFAULT 'once', -- 'once', 'daily', 'weekly', 'monthly'
    repeat_days TEXT, -- e.g. '[1,2,3]' or JSON
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.custom_notifications ENABLE ROW LEVEL SECURITY;

-- 15. Teacher Rate Templates
CREATE TABLE IF NOT EXISTS public.teacher_rate_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    rate_egp NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.teacher_rate_templates ENABLE ROW LEVEL SECURITY;

-- Create default RLS policies for simple access (Allow all operations for anon/authenticated during dev)
-- You can tighten these policies later in production.

DROP POLICY IF EXISTS "Allow all public reads" ON public.profiles;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.profiles;
CREATE POLICY "Allow all public reads" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.user_roles;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.user_roles;
CREATE POLICY "Allow all public reads" ON public.user_roles FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.user_roles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.signup_invites;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.signup_invites;
CREATE POLICY "Allow all public reads" ON public.signup_invites FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.signup_invites FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.families;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.families;
CREATE POLICY "Allow all public reads" ON public.families FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.families FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.students;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.students;
CREATE POLICY "Allow all public reads" ON public.students FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.students FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.teachers;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.teachers;
CREATE POLICY "Allow all public reads" ON public.teachers FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.teachers FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.recurring_lessons;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.recurring_lessons;
CREATE POLICY "Allow all public reads" ON public.recurring_lessons FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.recurring_lessons FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.lesson_students;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.lesson_students;
CREATE POLICY "Allow all public reads" ON public.lesson_students FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.lesson_students FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.lesson_sessions;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.lesson_sessions;
CREATE POLICY "Allow all public reads" ON public.lesson_sessions FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.lesson_sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.payments;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.payments;
CREATE POLICY "Allow all public reads" ON public.payments FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.payments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.family_invoices;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.family_invoices;
CREATE POLICY "Allow all public reads" ON public.family_invoices FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.family_invoices FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.issues;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.issues;
CREATE POLICY "Allow all public reads" ON public.issues FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.issues FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.teacher_evaluations;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.teacher_evaluations;
CREATE POLICY "Allow all public reads" ON public.teacher_evaluations FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.teacher_evaluations FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.custom_notifications;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.custom_notifications;
CREATE POLICY "Allow all public reads" ON public.custom_notifications FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.custom_notifications FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all public reads" ON public.teacher_rate_templates;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.teacher_rate_templates;
CREATE POLICY "Allow all public reads" ON public.teacher_rate_templates FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.teacher_rate_templates FOR ALL USING (true) WITH CHECK (true);

-- Trigger to automatically create profile and assign role on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (
    new.id,
    COALESCE(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1)
    )
  )
  ON CONFLICT (user_id) DO UPDATE
  SET display_name = EXCLUDED.display_name;
  
  -- Insert into user_roles as admin for the first user
  IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin' OR role = 'owner') THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (new.id, 'admin');
  ELSE
    INSERT INTO public.user_roles (user_id, role)
    VALUES (new.id, 'pending');
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 16. Push Subscriptions for Web Push Notifications
CREATE TABLE IF NOT EXISTS public.push_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID, -- Optional: links to auth.users if logged in
    endpoint TEXT UNIQUE NOT NULL,
    p256dh TEXT NOT NULL,
    auth TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all public reads" ON public.push_subscriptions;
DROP POLICY IF EXISTS "Allow all public modifications" ON public.push_subscriptions;
CREATE POLICY "Allow all public reads" ON public.push_subscriptions FOR SELECT USING (true);
CREATE POLICY "Allow all public modifications" ON public.push_subscriptions FOR ALL USING (true) WITH CHECK (true);

