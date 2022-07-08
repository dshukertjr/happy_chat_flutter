# Happy Chat

This is the Flutter version of the Happy Chat app build during the [Happy Hour stream](https://www.youtube.com/watch?v=sOSrPDtvvaQ&list=PL5S4mPUpp4OvEgxBhoVxXb5YS1ZAZih2l) by Supabase. 

## SQL

We use `CITEXt` postgres extention in this app. In order to enable this extention, go to Database -> Extentions and find `CITEXT` extention and enable it!

```sql
create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    username citext not null unique,

    -- using the same regex as instagram to check for username format
    constraint username_validation check (username ~* '^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$')
);
comment on table public.profiles is 'Holds all of users profile information';

create table if not exists public.rooms (
    id uuid not null primary key default uuid_generate_v4(),
    name text,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.rooms is 'Holds chat rooms';

create table if not exists public.room_participants (
    profile_id uuid references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    primary key (profile_id, room_id)
);
comment on table public.room_participants is 'Relational table of users and rooms.';

create table if not exists public.messages (
    id uuid not null primary key default uuid_generate_v4(),
    profile_id uuid default auth.uid() references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    content varchar(500) not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';

-- Enable realtime for messages table
alter publication supabase_realtime add table public.messages;

-- Returns true if the signed in user is a participant of the room
create or replace function is_room_participant(room_id uuid)
returns boolean as $$
  select exists(
    select 1
    from room_participants
    where room_id = is_room_participant.room_id and profile_id = auth.uid()
  );
$$ language sql security definer;

-- *** Row level security polities ***


alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);


alter table public.rooms enable row level security;
create policy "Users can view rooms that they have joined" on public.rooms for select using (is_room_participant(id));
create policy "Users can update the rooms that they are in." on public.rooms for update using (is_room_participant(id)) with check (is_room_participant(id));


alter table public.room_participants enable row level security;
create policy "Participants of the room can view other participants." on public.room_participants for select using (is_room_participant(room_id));


alter table public.messages enable row level security;
create policy "Users can view messages on rooms they are in." on public.messages for select using (is_room_participant(room_id));
create policy "Users can insert messages on rooms they are in." on public.messages for insert with check (is_room_participant(room_id) and profile_id = auth.uid());

-- Creates a new room and inserts the caller
create or replace function create_room(name text default null)
returns rooms as
$$
    declare
        v_room rooms;
    begin
        insert into public.rooms (name)
        values(create_room.name)

        returning * into v_room;

        insert into room_participants(room_id, profile_id)
        values(v_room.id, auth.uid());

        return v_room;
    end
$$ language plpgsql security definer;

-- Function to create a new row in profiles table upon signup
-- Also copies the username value from metadata
create or replace function handle_new_user() returns trigger as $$
    begin
        insert into public.profiles(id, username)
        values(new.id, new.raw_user_meta_data->>'username');

        return new;
    end;
$$ language plpgsql security definer;

-- Trigger to call `handle_new_user` when new user signs up
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function handle_new_user();
```