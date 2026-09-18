-- BILLY VIGIA - BANCO DE DADOS SUPABASE COMPLETO
-- Execute isso no SQL Editor do Supabase

-- 1. EXTENSÕES
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";

-- 2. TABELAS
-- Users com roles
create table public.users (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  role text check (role in ('cliente','vigilante','central')) not null,
  nome text not null,
  created_at timestamp default now()
);

-- Clientes
create table public.clientes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  nome text not null,
  endereco text not null,
  bairro text,
  cidade text default 'Itápolis',
  lat double precision,
  lng double precision,
  plano text check (plano in ('Essencial','Premium','Tático')) default 'Essencial',
  valor_mensalidade numeric(10,2) default 189.00,
  status text default 'ativo',
  frequencia_rondas int default 3,
  created_at timestamp default now()
);

-- Vigilantes
create table public.vigilantes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  nome text not null,
  moto_placa text,
  moto_modelo text,
  status text check (status in ('online','offline','em_ronda','em_ocorrencia')) default 'offline',
  lat double precision,
  lng double precision,
  horas_trabalhadas numeric default 0,
  avaliacao numeric(3,2) default 5.0,
  created_at timestamp default now()
);

-- Rondas
create table public.rondas (
  id uuid primary key default uuid_generate_v4(),
  cliente_id uuid references public.clientes(id) not null,
  vigilante_id uuid references public.vigilantes(id),
  inicio timestamp default now(),
  fim timestamp,
  status text check (status in ('agendada','em_andamento','concluida','com_ocorrencia')) default 'agendada',
  fotos text[] default '{}',
  checkin_lat double precision,
  checkin_lng double precision,
  duracao_min int,
  observacao text,
  created_at timestamp default now()
);

-- Ocorrências
create table public.ocorrencias (
  id uuid primary key default uuid_generate_v4(),
  ronda_id uuid references public.rondas(id),
  cliente_id uuid references public.clientes(id),
  tipo text check (tipo in ('Suspeito','Portao Aberto','Barulho','Iluminacao','Pânico','Outros')) not null,
  descricao text,
  gravidade text check (gravidade in ('baixa','media','alta','critica')) default 'media',
  foto_url text,
  audio_url text,
  status text check (status in ('pendente','em_atendimento','resolvida')) default 'pendente',
  lat double precision,
  lng double precision,
  created_at timestamp default now()
);

-- Financeiro
create table public.faturas (
  id uuid primary key default uuid_generate_v4(),
  cliente_id uuid references public.clientes(id) not null,
  valor numeric(10,2) not null,
  vencimento date not null,
  status text check (status in ('pago','pendente','atrasado')) default 'pendente',
  pix_qr text,
  created_at timestamp default now()
);

-- Push Subscriptions
create table public.push_subscriptions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  subscription jsonb not null,
  created_at timestamp default now()
);

-- 3. RLS (Row Level Security)
alter table public.users enable row level security;
alter table public.clientes enable row level security;
alter table public.vigilantes enable row level security;
alter table public.rondas enable row level security;
alter table public.ocorrencias enable row level security;
alter table public.faturas enable row level security;

create policy "Permitir tudo para demo" on public.users for all using (true) with check (true);
create policy "Permitir tudo para demo" on public.clientes for all using (true) with check (true);
create policy "Permitir tudo para demo" on public.vigilantes for all using (true) with check (true);
create policy "Permitir tudo para demo" on public.rondas for all using (true) with check (true);
create policy "Permitir tudo para demo" on public.ocorrencias for all using (true) with check (true);
create policy "Permitir tudo para demo" on public.faturas for all using (true) with check (true);

-- 4. DADOS MOCK DEMO
insert into public.users (email, role, nome) values
('cliente@demo.com','cliente','Residencial Flores'),
('vigilante@demo.com','vigilante','Marcos Silva'),
('central@demo.com','central','Central Billy Vigia');

-- Clientes Mock Itápolis-SP
insert into public.clientes (nome, endereco, bairro, lat, lng, plano, valor_mensalidade) values
('Residencial Flores','Rua José Rossi, 450','Centro', -21.5915, -48.8128, 'Premium', 189.00),
('Casa Dona Cida','Rua Padre Tarallo, 120','Jd. Silvério', -21.5930, -48.8150, 'Essencial', 129.00),
('Comercial Central','Av. Florêncio Terra, 800','Centro', -21.5900, -48.8100, 'Tático', 289.00),
('Chácara Bela Vista','Estrada Municipal, Km 2','Zona Rural', -21.5850, -48.8000, 'Premium', 189.00),
('Residência Almeida','Rua Duque de Caxias, 300','Jd. 2000', -21.5950, -48.8180, 'Essencial', 129.00),
('Loja Agropecuária','Rua Valentim Gentil, 500','Centro', -21.5890, -48.8115, 'Tático', 289.00),
('Casa Família Santos','Rua Emílio Mucare, 200','Portal', -21.5920, -48.8140, 'Premium', 189.00),
('Sítio São José','Rodovia SP-333','Rural', -21.5800, -48.7950, 'Premium', 189.00);

-- Vigilantes Mock
insert into public.vigilantes (nome, moto_placa, moto_modelo, status, lat, lng) values
('Marcos Silva','BRA2E19','Honda Bros 160','online', -21.5910, -48.8120),
('Jeferson Costa','CDE3F45','Yamaha Crosser 150','em_ronda', -21.5935, -48.8155),
('Roberto Alves','FGH7I89','Honda XRE 190','offline', -21.5905, -48.8110);

-- 5. REALTIME
alter publication supabase_realtime add table public.rondas;
alter publication supabase_realtime add table public.ocorrencias;
alter publication supabase_realtime add table public.vigilantes;

-- 6. STORAGE BUCKETS (criar via dashboard ou SQL)
-- insert into storage.buckets (id, name, public) values ('rondas-fotos','rondas-fotos', true);
-- insert into storage.buckets (id, name, public) values ('ocorrencias','ocorrencias', true);
