--
-- PostgreSQL database dump
--

\restrict NeolfGi18Rx6fAIpHDmb1UWG63Mql9kL6NRunzAkhUNsg5ncNmwHgDAG1Oe81mr

-- Dumped from database version 16.11 (Homebrew)
-- Dumped by pg_dump version 16.11 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accessories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accessories (
    id bigint NOT NULL,
    characteristics jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    last_seen_at timestamp(6) without time zone,
    name character varying,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    room_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uuid character varying
);


--
-- Name: accessories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accessories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accessories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accessories_id_seq OWNED BY public.accessories.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    content_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: control_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.control_events (
    id bigint NOT NULL,
    accessory_id bigint,
    action_type character varying NOT NULL,
    characteristic_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    error_message character varying,
    latency_ms double precision,
    new_value character varying,
    old_value character varying,
    request_id character varying,
    scene_id bigint,
    source character varying,
    success boolean DEFAULT true NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_ip character varying
);


--
-- Name: control_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.control_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: control_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.control_events_id_seq OWNED BY public.control_events.id;


--
-- Name: floorplans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.floorplans (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    home_id bigint NOT NULL,
    level integer,
    name character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: floorplans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.floorplans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: floorplans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.floorplans_id_seq OWNED BY public.floorplans.id;


--
-- Name: homekit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homekit_events (
    id bigint NOT NULL,
    accessory_id bigint,
    accessory_name character varying,
    characteristic character varying,
    created_at timestamp(6) without time zone NOT NULL,
    event_type character varying,
    raw_payload jsonb,
    sensor_id bigint,
    "timestamp" timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    value jsonb
);


--
-- Name: homekit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.homekit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: homekit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.homekit_events_id_seq OWNED BY public.homekit_events.id;


--
-- Name: homes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    homekit_home_id character varying,
    name character varying,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uuid character varying
);


--
-- Name: homes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.homes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: homes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.homes_id_seq OWNED BY public.homes.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    home_id bigint NOT NULL,
    last_event_at timestamp(6) without time zone,
    last_motion_at timestamp(6) without time zone,
    name character varying,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uuid character varying
);


--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: scene_accessories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scene_accessories (
    id bigint NOT NULL,
    accessory_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    scene_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: scene_accessories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scene_accessories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scene_accessories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scene_accessories_id_seq OWNED BY public.scene_accessories.id;


--
-- Name: scenes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    home_id bigint NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    name character varying,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uuid character varying
);


--
-- Name: scenes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenes_id_seq OWNED BY public.scenes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sensor_value_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_value_definitions (
    id bigint NOT NULL,
    accessory_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    label character varying,
    last_seen_at timestamp(6) without time zone,
    occurrence_count integer DEFAULT 0,
    room_id bigint,
    sensor_id bigint,
    units character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    value character varying
);


--
-- Name: sensor_value_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sensor_value_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensor_value_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sensor_value_definitions_id_seq OWNED BY public.sensor_value_definitions.id;


--
-- Name: sensors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensors (
    id bigint NOT NULL,
    accessory_id bigint NOT NULL,
    characteristic_homekit_type character varying,
    characteristic_type character varying NOT NULL,
    characteristic_uuid character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    current_value jsonb,
    is_writable boolean DEFAULT false,
    last_seen_at timestamp(6) without time zone,
    last_updated_at timestamp(6) without time zone,
    max_value double precision,
    metadata jsonb DEFAULT '{}'::jsonb,
    min_value double precision,
    properties jsonb DEFAULT '[]'::jsonb,
    service_type character varying NOT NULL,
    service_uuid character varying NOT NULL,
    step_value double precision,
    supports_events boolean DEFAULT false,
    units character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    value_format character varying
);


--
-- Name: sensors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sensors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sensors_id_seq OWNED BY public.sensors.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preferences (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    favorites text,
    session_id character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_preferences_id_seq OWNED BY public.user_preferences.id;


--
-- Name: accessories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories ALTER COLUMN id SET DEFAULT nextval('public.accessories_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: control_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_events ALTER COLUMN id SET DEFAULT nextval('public.control_events_id_seq'::regclass);


--
-- Name: floorplans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.floorplans ALTER COLUMN id SET DEFAULT nextval('public.floorplans_id_seq'::regclass);


--
-- Name: homekit_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homekit_events ALTER COLUMN id SET DEFAULT nextval('public.homekit_events_id_seq'::regclass);


--
-- Name: homes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homes ALTER COLUMN id SET DEFAULT nextval('public.homes_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Name: scene_accessories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_accessories ALTER COLUMN id SET DEFAULT nextval('public.scene_accessories_id_seq'::regclass);


--
-- Name: scenes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenes ALTER COLUMN id SET DEFAULT nextval('public.scenes_id_seq'::regclass);


--
-- Name: sensor_value_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_value_definitions ALTER COLUMN id SET DEFAULT nextval('public.sensor_value_definitions_id_seq'::regclass);


--
-- Name: sensors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors ALTER COLUMN id SET DEFAULT nextval('public.sensors_id_seq'::regclass);


--
-- Name: user_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences ALTER COLUMN id SET DEFAULT nextval('public.user_preferences_id_seq'::regclass);


--
-- Data for Name: accessories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.accessories (id, characteristics, created_at, last_seen_at, name, raw_data, room_id, updated_at, uuid) FROM stdin;
\.


--
-- Data for Name: active_storage_attachments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.active_storage_attachments (id, blob_id, created_at, name, record_id, record_type) FROM stdin;
\.


--
-- Data for Name: active_storage_blobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.active_storage_blobs (id, byte_size, checksum, content_type, created_at, filename, key, metadata, service_name) FROM stdin;
\.


--
-- Data for Name: active_storage_variant_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.active_storage_variant_records (id, blob_id, variation_digest) FROM stdin;
\.


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	test	2026-02-13 22:08:38.117131	2026-02-13 22:08:38.117132
schema_sha1	3870f24b4a40d655f48648de94fb0e9b1ef41856	2026-02-13 22:08:38.117754	2026-02-13 22:08:38.117755
\.


--
-- Data for Name: control_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.control_events (id, accessory_id, action_type, characteristic_name, created_at, error_message, latency_ms, new_value, old_value, request_id, scene_id, source, success, updated_at, user_ip) FROM stdin;
\.


--
-- Data for Name: floorplans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.floorplans (id, created_at, home_id, level, name, updated_at) FROM stdin;
\.


--
-- Data for Name: homekit_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.homekit_events (id, accessory_id, accessory_name, characteristic, created_at, event_type, raw_payload, sensor_id, "timestamp", updated_at, value) FROM stdin;
\.


--
-- Data for Name: homes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.homes (id, created_at, homekit_home_id, name, raw_data, updated_at, uuid) FROM stdin;
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rooms (id, created_at, home_id, last_event_at, last_motion_at, name, raw_data, updated_at, uuid) FROM stdin;
\.


--
-- Data for Name: scene_accessories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scene_accessories (id, accessory_id, created_at, scene_id, updated_at) FROM stdin;
\.


--
-- Data for Name: scenes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scenes (id, created_at, home_id, metadata, name, raw_data, updated_at, uuid) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version) FROM stdin;
20260213220526
20260213151800
20260208133157
20260207194124
20260207194024
20260206221803
20260206221802
20260206221801
20260126202725
20260126183458
20260126154554
20260125232719
20260125232718
20260125232716
20260125232715
20260125232713
20260125232712
\.


--
-- Data for Name: sensor_value_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sensor_value_definitions (id, accessory_id, created_at, label, last_seen_at, occurrence_count, room_id, sensor_id, units, updated_at, value) FROM stdin;
\.


--
-- Data for Name: sensors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sensors (id, accessory_id, characteristic_homekit_type, characteristic_type, characteristic_uuid, created_at, current_value, is_writable, last_seen_at, last_updated_at, max_value, metadata, min_value, properties, service_type, service_uuid, step_value, supports_events, units, updated_at, value_format) FROM stdin;
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_preferences (id, created_at, favorites, session_id, updated_at) FROM stdin;
\.


--
-- Name: accessories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.accessories_id_seq', 43, true);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.active_storage_attachments_id_seq', 1, false);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.active_storage_blobs_id_seq', 1, false);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.active_storage_variant_records_id_seq', 1, false);


--
-- Name: control_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.control_events_id_seq', 20, true);


--
-- Name: floorplans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.floorplans_id_seq', 1, false);


--
-- Name: homekit_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.homekit_events_id_seq', 1, false);


--
-- Name: homes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.homes_id_seq', 31, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rooms_id_seq', 31, true);


--
-- Name: scene_accessories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scene_accessories_id_seq', 1, false);


--
-- Name: scenes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scenes_id_seq', 1, false);


--
-- Name: sensor_value_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sensor_value_definitions_id_seq', 1, false);


--
-- Name: sensors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sensors_id_seq', 32, true);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_preferences_id_seq', 3, true);


--
-- Name: accessories accessories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories
    ADD CONSTRAINT accessories_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: control_events control_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_events
    ADD CONSTRAINT control_events_pkey PRIMARY KEY (id);


--
-- Name: floorplans floorplans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.floorplans
    ADD CONSTRAINT floorplans_pkey PRIMARY KEY (id);


--
-- Name: homekit_events homekit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homekit_events
    ADD CONSTRAINT homekit_events_pkey PRIMARY KEY (id);


--
-- Name: homes homes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homes
    ADD CONSTRAINT homes_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: scene_accessories scene_accessories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_accessories
    ADD CONSTRAINT scene_accessories_pkey PRIMARY KEY (id);


--
-- Name: scenes scenes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenes
    ADD CONSTRAINT scenes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sensor_value_definitions sensor_value_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_value_definitions
    ADD CONSTRAINT sensor_value_definitions_pkey PRIMARY KEY (id);


--
-- Name: sensors sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: index_accessories_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accessories_on_last_seen_at ON public.accessories USING btree (last_seen_at);


--
-- Name: index_accessories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accessories_on_name ON public.accessories USING btree (name);


--
-- Name: index_accessories_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accessories_on_room_id ON public.accessories USING btree (room_id);


--
-- Name: index_accessories_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accessories_on_uuid ON public.accessories USING btree (uuid);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_control_events_on_accessory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_accessory_id ON public.control_events USING btree (accessory_id);


--
-- Name: index_control_events_on_action_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_action_type ON public.control_events USING btree (action_type);


--
-- Name: index_control_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_created_at ON public.control_events USING btree (created_at);


--
-- Name: index_control_events_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_request_id ON public.control_events USING btree (request_id);


--
-- Name: index_control_events_on_scene_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_scene_id ON public.control_events USING btree (scene_id);


--
-- Name: index_control_events_on_success; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_control_events_on_success ON public.control_events USING btree (success);


--
-- Name: index_floorplans_on_home_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_floorplans_on_home_id ON public.floorplans USING btree (home_id);


--
-- Name: index_homekit_events_on_accessory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homekit_events_on_accessory_id ON public.homekit_events USING btree (accessory_id);


--
-- Name: index_homekit_events_on_accessory_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homekit_events_on_accessory_name ON public.homekit_events USING btree (accessory_name);


--
-- Name: index_homekit_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homekit_events_on_event_type ON public.homekit_events USING btree (event_type);


--
-- Name: index_homekit_events_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homekit_events_on_sensor_id ON public.homekit_events USING btree (sensor_id);


--
-- Name: index_homekit_events_on_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homekit_events_on_timestamp ON public.homekit_events USING btree ("timestamp");


--
-- Name: index_homes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homes_on_name ON public.homes USING btree (name);


--
-- Name: index_homes_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_homes_on_uuid ON public.homes USING btree (uuid);


--
-- Name: index_rooms_on_home_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_home_id ON public.rooms USING btree (home_id);


--
-- Name: index_rooms_on_last_event_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_last_event_at ON public.rooms USING btree (last_event_at);


--
-- Name: index_rooms_on_last_motion_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_last_motion_at ON public.rooms USING btree (last_motion_at);


--
-- Name: index_rooms_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_name ON public.rooms USING btree (name);


--
-- Name: index_rooms_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rooms_on_uuid ON public.rooms USING btree (uuid);


--
-- Name: index_scene_accessories_on_accessory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scene_accessories_on_accessory_id ON public.scene_accessories USING btree (accessory_id);


--
-- Name: index_scene_accessories_on_scene_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scene_accessories_on_scene_id ON public.scene_accessories USING btree (scene_id);


--
-- Name: index_scenes_on_home_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scenes_on_home_id ON public.scenes USING btree (home_id);


--
-- Name: index_scenes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scenes_on_name ON public.scenes USING btree (name);


--
-- Name: index_scenes_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_scenes_on_uuid ON public.scenes USING btree (uuid);


--
-- Name: index_sensor_value_definitions_on_accessory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_value_definitions_on_accessory_id ON public.sensor_value_definitions USING btree (accessory_id);


--
-- Name: index_sensor_value_definitions_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_value_definitions_on_room_id ON public.sensor_value_definitions USING btree (room_id);


--
-- Name: index_sensor_value_definitions_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_value_definitions_on_sensor_id ON public.sensor_value_definitions USING btree (sensor_id);


--
-- Name: index_sensor_value_definitions_on_sensor_id_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sensor_value_definitions_on_sensor_id_and_value ON public.sensor_value_definitions USING btree (sensor_id, value);


--
-- Name: index_sensors_on_accessory_and_characteristic; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sensors_on_accessory_and_characteristic ON public.sensors USING btree (accessory_id, characteristic_uuid);


--
-- Name: index_sensors_on_accessory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_accessory_id ON public.sensors USING btree (accessory_id);


--
-- Name: index_sensors_on_characteristic_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_characteristic_type ON public.sensors USING btree (characteristic_type);


--
-- Name: index_sensors_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_last_seen_at ON public.sensors USING btree (last_seen_at);


--
-- Name: index_sensors_on_last_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_last_updated_at ON public.sensors USING btree (last_updated_at);


--
-- Name: index_sensors_on_service_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_service_type ON public.sensors USING btree (service_type);


--
-- Name: index_sensors_on_supports_events; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_supports_events ON public.sensors USING btree (supports_events);


--
-- Name: homekit_events fk_rails_26c93a0f2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homekit_events
    ADD CONSTRAINT fk_rails_26c93a0f2a FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: scenes fk_rails_428e88a94a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenes
    ADD CONSTRAINT fk_rails_428e88a94a FOREIGN KEY (home_id) REFERENCES public.homes(id);


--
-- Name: scene_accessories fk_rails_469177f3ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_accessories
    ADD CONSTRAINT fk_rails_469177f3ee FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: sensor_value_definitions fk_rails_4a664764bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_value_definitions
    ADD CONSTRAINT fk_rails_4a664764bd FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: rooms fk_rails_53422ceb7a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT fk_rails_53422ceb7a FOREIGN KEY (home_id) REFERENCES public.homes(id);


--
-- Name: homekit_events fk_rails_5cbe448d05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homekit_events
    ADD CONSTRAINT fk_rails_5cbe448d05 FOREIGN KEY (sensor_id) REFERENCES public.sensors(id);


--
-- Name: accessories fk_rails_7bd1cfcd40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories
    ADD CONSTRAINT fk_rails_7bd1cfcd40 FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: control_events fk_rails_7ea63312ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_events
    ADD CONSTRAINT fk_rails_7ea63312ae FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: control_events fk_rails_8434cdab15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_events
    ADD CONSTRAINT fk_rails_8434cdab15 FOREIGN KEY (scene_id) REFERENCES public.scenes(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: sensors fk_rails_9c3f3ea5e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT fk_rails_9c3f3ea5e8 FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: floorplans fk_rails_ca874d3cd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.floorplans
    ADD CONSTRAINT fk_rails_ca874d3cd9 FOREIGN KEY (home_id) REFERENCES public.homes(id);


--
-- Name: scene_accessories fk_rails_d43e2d93be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_accessories
    ADD CONSTRAINT fk_rails_d43e2d93be FOREIGN KEY (scene_id) REFERENCES public.scenes(id);


--
-- Name: sensor_value_definitions fk_rails_f3ec85a8c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_value_definitions
    ADD CONSTRAINT fk_rails_f3ec85a8c7 FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: sensor_value_definitions fk_rails_fc0f01f4f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_value_definitions
    ADD CONSTRAINT fk_rails_fc0f01f4f5 FOREIGN KEY (sensor_id) REFERENCES public.sensors(id);


--
-- PostgreSQL database dump complete
--

\unrestrict NeolfGi18Rx6fAIpHDmb1UWG63Mql9kL6NRunzAkhUNsg5ncNmwHgDAG1Oe81mr

