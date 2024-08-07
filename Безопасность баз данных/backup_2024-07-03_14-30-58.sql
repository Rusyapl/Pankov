PGDMP  ;                    |            rusya    16.1    16.1 �    {           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            |           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            }           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            ~           1262    32768    rusya    DATABASE     y   CREATE DATABASE rusya WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE rusya;
                postgres    false                       0    0    SCHEMA public    ACL     1   GRANT USAGE ON SCHEMA public TO user_admin_role;
                   pg_database_owner    false    7                        3079    49156 	   adminpack 	   EXTENSION     A   CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;
    DROP EXTENSION adminpack;
                   false            �           0    0    EXTENSION adminpack    COMMENT     M   COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';
                        false    3                        3079    32896    pgcrypto 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
    DROP EXTENSION pgcrypto;
                   false            �           0    0    EXTENSION pgcrypto    COMMENT     <   COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
                        false    2            -           1255    49426    check_quantity()    FUNCTION     2  CREATE FUNCTION public.check_quantity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.count_tovara > (SELECT quantity FROM store WHERE store.id_tovara = NEW.id_tovara)) THEN
        RAISE EXCEPTION 'Count tovara cannot be less than store quantity.';
    END IF;
    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.check_quantity();
       public          postgres    false                       1255    32890    check_time_access()    FUNCTION     6  CREATE FUNCTION public.check_time_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (EXTRACT(HOUR FROM CURRENT_TIME) >= 8 AND EXTRACT(HOUR FROM CURRENT_TIME) < 20) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Access denied: Tables can only be accessed from 8am to 8pm';
  END IF;
END;
$$;
 *   DROP FUNCTION public.check_time_access();
       public          postgres    false            #           1255    49167    create_new_category() 	   PROCEDURE     *  CREATE PROCEDURE public.create_new_category()
    LANGUAGE plpgsql
    AS $$
DECLARE 
r RECORD;
BEGIN
	FOR r IN SELECT id_tovara, quantity FROM store WHERE quantity < 20 LOOP
	INSERT INTO orders (id_tovara, quantity, date_order)
	VALUES (r.id_tovara, 100, current_date);
END LOOP;
COMMIT;
END;
$$;
 -   DROP PROCEDURE public.create_new_category();
       public          postgres    false            $           1255    49168 /   create_new_category(integer, character varying) 	   PROCEDURE     �   CREATE PROCEDURE public.create_new_category(IN new_category_id integer, IN new_category_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO otdeli (id_otdela, name_otdela)
    VALUES (new_category_id, new_category_name);
END;
$$;
 o   DROP PROCEDURE public.create_new_category(IN new_category_id integer, IN new_category_name character varying);
       public          postgres    false            %           1255    32961    decryption(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.decryption(IN id_new integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
	new_key TEXT;
	decrypted_email TEXT;
BEGIN
	SELECT key_encr.key INTO new_key
	FROM key_encr
	WHERE key_encr.id = id_new;
	
    SELECT pgp_sym_decrypt(email::bytea, new_key) INTO decrypted_email
	FROM pokupateli
	JOIN users on users.id_usera = pokupateli.id_pokupatelya
	WHERE users.id_usera = id_new;
	
	RAISE NOTICE 'Decrypted password: %', decrypted_email::text;
END;
$$;
 5   DROP PROCEDURE public.decryption(IN id_new integer);
       public          postgres    false            )           1255    49169    empty_function()    FUNCTION     �   CREATE FUNCTION public.empty_function() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  --Пустой блок кода функции
END;
$$;
 '   DROP FUNCTION public.empty_function();
       public          postgres    false            �           0    0    FUNCTION empty_function()    ACL     8   GRANT ALL ON FUNCTION public.empty_function() TO user3;
          public          postgres    false    297            �            1255    32974    encrypt_data_v2()    FUNCTION     i  CREATE FUNCTION public.encrypt_data_v2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO key_encr(id, key)
	VALUES (NEW.id_pokupatelya, gen_random_bytes(32));
    NEW.email := pgp_sym_encrypt(NEW.email::text, (
		SELECT key_encr.key
		FROM key_encr
		ORDER BY key_encr.id DESC
		LIMIT 1)::text, 'cipher-algo=aes256');
    RETURN NEW;
END;
$$;
 (   DROP FUNCTION public.encrypt_data_v2();
       public          postgres    false            &           1255    49170    generate_keys()    FUNCTION     �   CREATE FUNCTION public.generate_keys() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    CREATE TABLE IF NOT EXISTS encryption_keys (
        key_id SERIAL PRIMARY KEY,
        encryption_key BYTEA
    );
END;
$$;
 &   DROP FUNCTION public.generate_keys();
       public          postgres    false                       1255    32962    hash_with_md5(text)    FUNCTION     �   CREATE FUNCTION public.hash_with_md5(input_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN crypt(input_text, gen_salt('md5'));
END;
$$;
 5   DROP FUNCTION public.hash_with_md5(input_text text);
       public          postgres    false            '           1255    49171    insert_encryption_key(bytea)    FUNCTION     �   CREATE FUNCTION public.insert_encryption_key(key_data bytea) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO encryption_keys (encryption_key) VALUES (key_data);
END;
$$;
 <   DROP FUNCTION public.insert_encryption_key(key_data bytea);
       public          postgres    false            ,           1255    40991    track_access()    FUNCTION     �  CREATE FUNCTION public.track_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO audit_count (date, access_count_to_reviews)
        VALUES (CURRENT_DATE, 1)
        ON CONFLICT (date)
        DO UPDATE SET access_count_to_reviews = audit_count.access_count_to_reviews + 1;
    END IF;
    
    RETURN NULL;
END;
$$;
 %   DROP FUNCTION public.track_access();
       public          postgres    false            �            1255    40983    track_deleted_reviews()    FUNCTION     �   CREATE FUNCTION public.track_deleted_reviews() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO audit (table_name, row_data) VALUES (TG_TABLE_NAME, row_to_json(OLD));
    RETURN OLD;
END;
$$;
 .   DROP FUNCTION public.track_deleted_reviews();
       public          postgres    false            (           1255    49172    track_events()    FUNCTION     �  CREATE FUNCTION public.track_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO audit_counts (date, count_events)
        VALUES (CURRENT_DATE, 1)
        ON CONFLICT (date)
        DO UPDATE SET count_events = audit_counts.count_events + 1;
    END IF;
    
    RETURN NULL;
END;
$$;
 %   DROP FUNCTION public.track_events();
       public          postgres    false            *           1255    32880    update_store()    FUNCTION     �  CREATE FUNCTION public.update_store() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM store WHERE id_tovara = NEW.id_tovara) THEN
        UPDATE store
        SET
            quantity = store.quantity + NEW.count_tovara
        WHERE id_tovara = NEW.id_tovara;
    ELSE
        INSERT INTO store (id_tovara, quantity, price)
        VALUES (NEW.id_tovara, NEW.count_tovara, NEW.cost_1);
    END IF;
    RETURN NEW;
END;
$$;
 %   DROP FUNCTION public.update_store();
       public          postgres    false            �           0    0    FUNCTION update_store()    ACL     6   GRANT ALL ON FUNCTION public.update_store() TO user3;
          public          postgres    false    298            �            1255    32882    update_store_quantity()    FUNCTION     �   CREATE FUNCTION public.update_store_quantity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE store
	SET quantity = store.quantity - NEW.count_tovara
	WHERE id_tovara = NEW.id_tovara;
    RETURN NEW;
END;


$$;
 .   DROP FUNCTION public.update_store_quantity();
       public          postgres    false            �           0    0     FUNCTION update_store_quantity()    ACL     ?   GRANT ALL ON FUNCTION public.update_store_quantity() TO user3;
          public          postgres    false    240            +           1255    32879    zakaz() 	   PROCEDURE       CREATE PROCEDURE public.zakaz()
    LANGUAGE plpgsql
    AS $$
DECLARE 
r RECORD;
BEGIN
	FOR r IN SELECT id_tovara, quantity FROM store WHERE quantity < 10 LOOP
	INSERT INTO orders (id_tovara, quantity, date_order)
	VALUES (r.id_tovara, 100, current_date);
END LOOP;
END;
$$;
    DROP PROCEDURE public.zakaz();
       public          postgres    false            �           0    0    PROCEDURE zakaz()    ACL     0   GRANT ALL ON PROCEDURE public.zakaz() TO user2;
          public          postgres    false    299            �            1259    32799    adresses    TABLE     �   CREATE TABLE public.adresses (
    id_adresa integer NOT NULL,
    id_pokupatelya integer NOT NULL,
    adress character varying(30)
);
    DROP TABLE public.adresses;
       public         heap    postgres    false            �           0    0    TABLE adresses    ACL     :   GRANT SELECT ON TABLE public.adresses TO user_admin_role;
          public          postgres    false    222            �            1259    40974    audit    TABLE     �   CREATE TABLE public.audit (
    id integer NOT NULL,
    table_name character varying(255) NOT NULL,
    row_data jsonb NOT NULL,
    deleted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.audit;
       public         heap    postgres    false            �           0    0    TABLE audit    ACL     7   GRANT SELECT ON TABLE public.audit TO user_admin_role;
          public          postgres    false    232            �            1259    40986    audit_count    TABLE     a   CREATE TABLE public.audit_count (
    date date NOT NULL,
    access_count_to_reviews integer
);
    DROP TABLE public.audit_count;
       public         heap    postgres    false            �           0    0    TABLE audit_count    ACL     =   GRANT SELECT ON TABLE public.audit_count TO user_admin_role;
          public          postgres    false    233            �            1259    49174    audit_counts    TABLE     W   CREATE TABLE public.audit_counts (
    date date NOT NULL,
    count_events integer
);
     DROP TABLE public.audit_counts;
       public         heap    postgres    false            �           0    0    TABLE audit_counts    ACL     >   GRANT SELECT ON TABLE public.audit_counts TO user_admin_role;
          public          postgres    false    234            �            1259    49177    audit_id_audit_seq    SEQUENCE     �   CREATE SEQUENCE public.audit_id_audit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.audit_id_audit_seq;
       public          postgres    false            �            1259    40973    audit_id_seq    SEQUENCE     �   CREATE SEQUENCE public.audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.audit_id_seq;
       public          postgres    false    232            �           0    0    audit_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.audit_id_seq OWNED BY public.audit.id;
          public          postgres    false    231            �            1259    49178    encryption_keys    TABLE     _   CREATE TABLE public.encryption_keys (
    key_id integer NOT NULL,
    encryption_key bytea
);
 #   DROP TABLE public.encryption_keys;
       public         heap    postgres    false            �           0    0    TABLE encryption_keys    ACL     A   GRANT SELECT ON TABLE public.encryption_keys TO user_admin_role;
          public          postgres    false    236            �            1259    49183    encryption_keys_key_id_seq    SEQUENCE     �   CREATE SEQUENCE public.encryption_keys_key_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.encryption_keys_key_id_seq;
       public          postgres    false    236            �           0    0    encryption_keys_key_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.encryption_keys_key_id_seq OWNED BY public.encryption_keys.key_id;
          public          postgres    false    237            �            1259    32804    reviews    TABLE     |   CREATE TABLE public.reviews (
    id_review integer NOT NULL,
    id_prodaji integer NOT NULL,
    ball integer NOT NULL
);
    DROP TABLE public.reviews;
       public         heap    postgres    false            �           0    0    TABLE reviews    ACL     6   GRANT ALL ON TABLE public.reviews TO user_admin_role;
          public          postgres    false    223            �            1259    32892    get_10    VIEW     �   CREATE VIEW public.get_10 AS
 SELECT id_review,
    id_prodaji,
    ball
   FROM public.reviews
 LIMIT ( SELECT ((count(*))::numeric * 0.12)
           FROM public.reviews reviews_1);
    DROP VIEW public.get_10;
       public          postgres    false    223    223    223            �           0    0    TABLE get_10    ACL     8   GRANT SELECT ON TABLE public.get_10 TO user_admin_role;
          public          postgres    false    228            �            1259    32934    key_encr    TABLE     H   CREATE TABLE public.key_encr (
    id integer NOT NULL,
    key text
);
    DROP TABLE public.key_encr;
       public         heap    postgres    false            �           0    0    TABLE key_encr    ACL     :   GRANT SELECT ON TABLE public.key_encr TO user_admin_role;
          public          postgres    false    230            �            1259    32933    key_encr_id_seq    SEQUENCE     �   CREATE SEQUENCE public.key_encr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.key_encr_id_seq;
       public          postgres    false    230            �           0    0    key_encr_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.key_encr_id_seq OWNED BY public.key_encr.id;
          public          postgres    false    229            �            1259    32874    orders    TABLE     j   CREATE TABLE public.orders (
    id_tovara integer NOT NULL,
    quantity integer,
    date_order date
);
    DROP TABLE public.orders;
       public         heap    postgres    false            �           0    0    TABLE orders    ACL     �   GRANT SELECT,INSERT,DELETE ON TABLE public.orders TO user_prod_role;
GRANT SELECT ON TABLE public.orders TO user2;
GRANT SELECT ON TABLE public.orders TO user_admin_role;
          public          postgres    false    226            �            1259    32769    otdeli    TABLE     f   CREATE TABLE public.otdeli (
    id_otdela integer NOT NULL,
    name_otdela character varying(30)
);
    DROP TABLE public.otdeli;
       public         heap    postgres    false            �           0    0    TABLE otdeli    ACL     8   GRANT SELECT ON TABLE public.otdeli TO user_admin_role;
          public          postgres    false    217            �            1259    32774 
   pokupateli    TABLE     �   CREATE TABLE public.pokupateli (
    id_pokupatelya integer NOT NULL,
    name character varying(30),
    surname character varying(30),
    phone_number character varying(20),
    email character(1000)
);
    DROP TABLE public.pokupateli;
       public         heap    postgres    false            �           0    0    TABLE pokupateli    ACL     <   GRANT SELECT ON TABLE public.pokupateli TO user_admin_role;
          public          postgres    false    218            �            1259    32789    prodaji    TABLE       CREATE TABLE public.prodaji (
    id_prodaji integer NOT NULL,
    id_adresa integer,
    id_pokupatelya integer,
    date_prodaji date,
    id_postavki integer,
    count_tovara integer,
    id_tovara integer,
    CONSTRAINT check_date CHECK ((date_prodaji <= CURRENT_TIMESTAMP))
);
    DROP TABLE public.prodaji;
       public         heap    postgres    false            �           0    0    TABLE prodaji    ACL     9   GRANT SELECT ON TABLE public.prodaji TO user_admin_role;
          public          postgres    false    220            �            1259    32861    users    TABLE     M   CREATE TABLE public.users (
    id_usera integer NOT NULL,
    login text
);
    DROP TABLE public.users;
       public         heap    postgres    false            �           0    0    TABLE users    ACL     �   GRANT ALL ON TABLE public.users TO user_admin_role;
GRANT SELECT ON TABLE public.users TO user_pok_role;
GRANT UPDATE ON TABLE public.users TO user4;
          public          postgres    false    224            �            1259    32870    pokupki    VIEW     �  CREATE VIEW public.pokupki AS
 SELECT p.id_prodaji,
    p.id_adresa,
    p.id_pokupatelya,
    p.date_prodaji,
    p.id_postavki,
    p.count_tovara,
    p.id_tovara
   FROM (public.prodaji p
     JOIN public.users u ON ((u.id_usera = p.id_pokupatelya)))
  WHERE (u.id_usera = ( SELECT users.id_usera
           FROM public.users
          WHERE (users.login = SESSION_USER)))
  ORDER BY p.date_prodaji;
    DROP VIEW public.pokupki;
       public          postgres    false    220    220    220    220    220    220    224    224    220            �           0    0    TABLE pokupki    ACL     p   GRANT SELECT ON TABLE public.pokupki TO user_pok_role;
GRANT SELECT ON TABLE public.pokupki TO user_admin_role;
          public          postgres    false    225            �            1259    32779    postavka    TABLE     M  CREATE TABLE public.postavka (
    id_postavki integer NOT NULL,
    id_tovara integer,
    count_tovara integer,
    date_postavki date,
    production_date date,
    expiry_date date,
    cost_1 integer,
    CONSTRAINT check_date_postavki CHECK ((date_postavki <= CURRENT_TIMESTAMP)),
    CONSTRAINT check_date_production CHECK (((production_date <= CURRENT_TIMESTAMP) AND (production_date <= date_postavki))),
    CONSTRAINT check_expiry_date CHECK (((expiry_date <= CURRENT_TIMESTAMP) AND (expiry_date >= production_date))),
    CONSTRAINT check_quantity CHECK ((count_tovara > 0))
);
    DROP TABLE public.postavka;
       public         heap    postgres    false            �           0    0    TABLE postavka    ACL     :   GRANT SELECT ON TABLE public.postavka TO user_admin_role;
          public          postgres    false    219            �            1259    49184    purchase_changes_log    TABLE       CREATE TABLE public.purchase_changes_log (
    id_prodaji integer,
    id_adresa integer,
    id_pokupatelya integer,
    date_prodaji date,
    id_postavki integer,
    count_tovara integer,
    id_tovara integer,
    date_change date,
    changed_by character(50)
);
 (   DROP TABLE public.purchase_changes_log;
       public         heap    postgres    false            �           0    0    TABLE purchase_changes_log    ACL     F   GRANT SELECT ON TABLE public.purchase_changes_log TO user_admin_role;
          public          postgres    false    238            �            1259    32884    store    TABLE     ^   CREATE TABLE public.store (
    id_tovara integer,
    quantity integer,
    price integer
);
    DROP TABLE public.store;
       public         heap    postgres    false            �           0    0    TABLE store    ACL     �   GRANT SELECT,INSERT,DELETE ON TABLE public.store TO user_prod_role;
GRANT SELECT ON TABLE public.store TO user2;
GRANT SELECT ON TABLE public.store TO user_admin_role;
          public          postgres    false    227            �            1259    32794    tovari    TABLE     }   CREATE TABLE public.tovari (
    id_tovara integer NOT NULL,
    name_tovara character varying(30),
    id_otdela integer
);
    DROP TABLE public.tovari;
       public         heap    postgres    false            �           0    0    TABLE tovari    ACL     8   GRANT SELECT ON TABLE public.tovari TO user_admin_role;
          public          postgres    false    221            �           2604    40977    audit id    DEFAULT     d   ALTER TABLE ONLY public.audit ALTER COLUMN id SET DEFAULT nextval('public.audit_id_seq'::regclass);
 7   ALTER TABLE public.audit ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    231    232    232            �           2604    49187    encryption_keys key_id    DEFAULT     �   ALTER TABLE ONLY public.encryption_keys ALTER COLUMN key_id SET DEFAULT nextval('public.encryption_keys_key_id_seq'::regclass);
 E   ALTER TABLE public.encryption_keys ALTER COLUMN key_id DROP DEFAULT;
       public          postgres    false    237    236            �           2604    49188    key_encr id    DEFAULT     j   ALTER TABLE ONLY public.key_encr ALTER COLUMN id SET DEFAULT nextval('public.key_encr_id_seq'::regclass);
 :   ALTER TABLE public.key_encr ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    230    229    230            j          0    32799    adresses 
   TABLE DATA           E   COPY public.adresses (id_adresa, id_pokupatelya, adress) FROM stdin;
    public          postgres    false    222   0�       r          0    40974    audit 
   TABLE DATA           E   COPY public.audit (id, table_name, row_data, deleted_at) FROM stdin;
    public          postgres    false    232   y�       s          0    40986    audit_count 
   TABLE DATA           D   COPY public.audit_count (date, access_count_to_reviews) FROM stdin;
    public          postgres    false    233   ��       t          0    49174    audit_counts 
   TABLE DATA           :   COPY public.audit_counts (date, count_events) FROM stdin;
    public          postgres    false    234   ɝ       v          0    49178    encryption_keys 
   TABLE DATA           A   COPY public.encryption_keys (key_id, encryption_key) FROM stdin;
    public          postgres    false    236   ��       p          0    32934    key_encr 
   TABLE DATA           +   COPY public.key_encr (id, key) FROM stdin;
    public          postgres    false    230   S�       m          0    32874    orders 
   TABLE DATA           A   COPY public.orders (id_tovara, quantity, date_order) FROM stdin;
    public          postgres    false    226   ��       e          0    32769    otdeli 
   TABLE DATA           8   COPY public.otdeli (id_otdela, name_otdela) FROM stdin;
    public          postgres    false    217   ��       f          0    32774 
   pokupateli 
   TABLE DATA           X   COPY public.pokupateli (id_pokupatelya, name, surname, phone_number, email) FROM stdin;
    public          postgres    false    218   �       g          0    32779    postavka 
   TABLE DATA           }   COPY public.postavka (id_postavki, id_tovara, count_tovara, date_postavki, production_date, expiry_date, cost_1) FROM stdin;
    public          postgres    false    219   ��       h          0    32789    prodaji 
   TABLE DATA           |   COPY public.prodaji (id_prodaji, id_adresa, id_pokupatelya, date_prodaji, id_postavki, count_tovara, id_tovara) FROM stdin;
    public          postgres    false    220   ޣ       x          0    49184    purchase_changes_log 
   TABLE DATA           �   COPY public.purchase_changes_log (id_prodaji, id_adresa, id_pokupatelya, date_prodaji, id_postavki, count_tovara, id_tovara, date_change, changed_by) FROM stdin;
    public          postgres    false    238   O�       k          0    32804    reviews 
   TABLE DATA           >   COPY public.reviews (id_review, id_prodaji, ball) FROM stdin;
    public          postgres    false    223   ��       n          0    32884    store 
   TABLE DATA           ;   COPY public.store (id_tovara, quantity, price) FROM stdin;
    public          postgres    false    227   �       i          0    32794    tovari 
   TABLE DATA           C   COPY public.tovari (id_tovara, name_tovara, id_otdela) FROM stdin;
    public          postgres    false    221   �       l          0    32861    users 
   TABLE DATA           0   COPY public.users (id_usera, login) FROM stdin;
    public          postgres    false    224   [�       �           0    0    audit_id_audit_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.audit_id_audit_seq', 7, true);
          public          postgres    false    235            �           0    0    audit_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.audit_id_seq', 17, true);
          public          postgres    false    231            �           0    0    encryption_keys_key_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.encryption_keys_key_id_seq', 7, true);
          public          postgres    false    237            �           0    0    key_encr_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.key_encr_id_seq', 1, false);
          public          postgres    false    229            �           2606    32803    adresses adresses_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.adresses
    ADD CONSTRAINT adresses_pkey PRIMARY KEY (id_adresa);
 @   ALTER TABLE ONLY public.adresses DROP CONSTRAINT adresses_pkey;
       public            postgres    false    222            �           2606    40990    audit_count audit_count_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.audit_count
    ADD CONSTRAINT audit_count_pkey PRIMARY KEY (date);
 F   ALTER TABLE ONLY public.audit_count DROP CONSTRAINT audit_count_pkey;
       public            postgres    false    233            �           2606    49190    audit_counts audit_counts_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.audit_counts
    ADD CONSTRAINT audit_counts_pkey PRIMARY KEY (date);
 H   ALTER TABLE ONLY public.audit_counts DROP CONSTRAINT audit_counts_pkey;
       public            postgres    false    234            �           2606    40982    audit audit_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.audit
    ADD CONSTRAINT audit_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.audit DROP CONSTRAINT audit_pkey;
       public            postgres    false    232            �           2606    49192 $   encryption_keys encryption_keys_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.encryption_keys
    ADD CONSTRAINT encryption_keys_pkey PRIMARY KEY (key_id);
 N   ALTER TABLE ONLY public.encryption_keys DROP CONSTRAINT encryption_keys_pkey;
       public            postgres    false    236            �           2606    32941    key_encr key_encr_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.key_encr
    ADD CONSTRAINT key_encr_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.key_encr DROP CONSTRAINT key_encr_pkey;
       public            postgres    false    230            �           2606    32878    orders orders_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id_tovara);
 <   ALTER TABLE ONLY public.orders DROP CONSTRAINT orders_pkey;
       public            postgres    false    226            �           2606    32773    otdeli otdeli_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.otdeli
    ADD CONSTRAINT otdeli_pkey PRIMARY KEY (id_otdela);
 <   ALTER TABLE ONLY public.otdeli DROP CONSTRAINT otdeli_pkey;
       public            postgres    false    217            �           2606    32778    pokupateli pokupateli_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.pokupateli
    ADD CONSTRAINT pokupateli_pkey PRIMARY KEY (id_pokupatelya);
 D   ALTER TABLE ONLY public.pokupateli DROP CONSTRAINT pokupateli_pkey;
       public            postgres    false    218            �           2606    32783    postavka postavka_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.postavka
    ADD CONSTRAINT postavka_pkey PRIMARY KEY (id_postavki);
 @   ALTER TABLE ONLY public.postavka DROP CONSTRAINT postavka_pkey;
       public            postgres    false    219            �           2606    32867 "   users pr_key_usera_logins_id_usera 
   CONSTRAINT     f   ALTER TABLE ONLY public.users
    ADD CONSTRAINT pr_key_usera_logins_id_usera PRIMARY KEY (id_usera);
 L   ALTER TABLE ONLY public.users DROP CONSTRAINT pr_key_usera_logins_id_usera;
       public            postgres    false    224            �           2606    32793    prodaji prodaji_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.prodaji
    ADD CONSTRAINT prodaji_pkey PRIMARY KEY (id_prodaji);
 >   ALTER TABLE ONLY public.prodaji DROP CONSTRAINT prodaji_pkey;
       public            postgres    false    220            �           2606    32808    reviews reviews_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id_review);
 >   ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_pkey;
       public            postgres    false    223            �           2606    32798    tovari tovari_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.tovari
    ADD CONSTRAINT tovari_pkey PRIMARY KEY (id_tovara);
 <   ALTER TABLE ONLY public.tovari DROP CONSTRAINT tovari_pkey;
       public            postgres    false    221            �           2606    32869    users users_login_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_login_key;
       public            postgres    false    224            �           2620    40992    reviews access_trigger    TRIGGER     �   CREATE TRIGGER access_trigger AFTER INSERT OR DELETE OR UPDATE ON public.reviews FOR EACH STATEMENT EXECUTE FUNCTION public.track_access();
 /   DROP TRIGGER access_trigger ON public.reviews;
       public          postgres    false    300    223            �           2620    49427    prodaji check_quantity_trigger    TRIGGER     �   CREATE TRIGGER check_quantity_trigger BEFORE INSERT OR UPDATE ON public.prodaji FOR EACH ROW EXECUTE FUNCTION public.check_quantity();
 7   DROP TRIGGER check_quantity_trigger ON public.prodaji;
       public          postgres    false    220    301            �           2620    40985    adresses delete_review_trigger    TRIGGER     �   CREATE TRIGGER delete_review_trigger AFTER DELETE ON public.adresses FOR EACH ROW EXECUTE FUNCTION public.track_deleted_reviews();
 7   DROP TRIGGER delete_review_trigger ON public.adresses;
       public          postgres    false    222    241            �           2620    40984    reviews delete_review_trigger    TRIGGER     �   CREATE TRIGGER delete_review_trigger AFTER DELETE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.track_deleted_reviews();
 6   DROP TRIGGER delete_review_trigger ON public.reviews;
       public          postgres    false    223    241            �           2620    32975    pokupateli encrypt_trigger    TRIGGER     z   CREATE TRIGGER encrypt_trigger BEFORE INSERT ON public.pokupateli FOR EACH ROW EXECUTE FUNCTION public.encrypt_data_v2();
 3   DROP TRIGGER encrypt_trigger ON public.pokupateli;
       public          postgres    false    218    239            �           2620    32891    users time_access_trigger    TRIGGER     �   CREATE TRIGGER time_access_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.check_time_access();
 2   DROP TRIGGER time_access_trigger ON public.users;
       public          postgres    false    224    283            �           2620    49196    prodaji trigger_events    TRIGGER     �   CREATE TRIGGER trigger_events AFTER INSERT OR DELETE OR UPDATE ON public.prodaji FOR EACH STATEMENT EXECUTE FUNCTION public.track_events();
 /   DROP TRIGGER trigger_events ON public.prodaji;
       public          postgres    false    220    296            �           2620    32881    postavka update_after_store    TRIGGER     w   CREATE TRIGGER update_after_store AFTER INSERT ON public.postavka FOR EACH ROW EXECUTE FUNCTION public.update_store();
 4   DROP TRIGGER update_after_store ON public.postavka;
       public          postgres    false    219    298            �           2620    32883     prodaji update_store_after_sales    TRIGGER     �   CREATE TRIGGER update_store_after_sales AFTER INSERT ON public.prodaji FOR EACH ROW EXECUTE FUNCTION public.update_store_quantity();
 9   DROP TRIGGER update_store_after_sales ON public.prodaji;
       public          postgres    false    240    220            �           2606    32834    prodaji fk_adress    FK CONSTRAINT     |   ALTER TABLE ONLY public.prodaji
    ADD CONSTRAINT fk_adress FOREIGN KEY (id_adresa) REFERENCES public.adresses(id_adresa);
 ;   ALTER TABLE ONLY public.prodaji DROP CONSTRAINT fk_adress;
       public          postgres    false    222    4779    220            �           2606    32819    adresses fk_pokupatelya    FK CONSTRAINT     �   ALTER TABLE ONLY public.adresses
    ADD CONSTRAINT fk_pokupatelya FOREIGN KEY (id_pokupatelya) REFERENCES public.pokupateli(id_pokupatelya);
 A   ALTER TABLE ONLY public.adresses DROP CONSTRAINT fk_pokupatelya;
       public          postgres    false    4771    218    222            �           2606    32829    prodaji fk_pokupatelya    FK CONSTRAINT     �   ALTER TABLE ONLY public.prodaji
    ADD CONSTRAINT fk_pokupatelya FOREIGN KEY (id_pokupatelya) REFERENCES public.pokupateli(id_pokupatelya);
 @   ALTER TABLE ONLY public.prodaji DROP CONSTRAINT fk_pokupatelya;
       public          postgres    false    220    4771    218            �           2606    32824    prodaji fk_postavka    FK CONSTRAINT     �   ALTER TABLE ONLY public.prodaji
    ADD CONSTRAINT fk_postavka FOREIGN KEY (id_postavki) REFERENCES public.postavka(id_postavki);
 =   ALTER TABLE ONLY public.prodaji DROP CONSTRAINT fk_postavka;
       public          postgres    false    4773    219    220            �           2606    32809    reviews fk_prodaji    FK CONSTRAINT     ~   ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_prodaji FOREIGN KEY (id_prodaji) REFERENCES public.prodaji(id_prodaji);
 <   ALTER TABLE ONLY public.reviews DROP CONSTRAINT fk_prodaji;
       public          postgres    false    4775    223    220            �           2606    32844    postavka fk_tovara    FK CONSTRAINT     {   ALTER TABLE ONLY public.postavka
    ADD CONSTRAINT fk_tovara FOREIGN KEY (id_tovara) REFERENCES public.tovari(id_tovara);
 <   ALTER TABLE ONLY public.postavka DROP CONSTRAINT fk_tovara;
       public          postgres    false    221    219    4777            �           2606    32814    tovari fk_отделы    FK CONSTRAINT     �   ALTER TABLE ONLY public.tovari
    ADD CONSTRAINT "fk_отделы" FOREIGN KEY (id_otdela) REFERENCES public.otdeli(id_otdela);
 B   ALTER TABLE ONLY public.tovari DROP CONSTRAINT "fk_отделы";
       public          postgres    false    221    4769    217            a           3256    40997    prodaji only_pokupateli    POLICY       CREATE POLICY only_pokupateli ON public.prodaji WITH CHECK ((id_pokupatelya = ( SELECT prodaji_1.id_pokupatelya
   FROM (public.prodaji prodaji_1
     JOIN public.users ON ((users.id_usera = prodaji_1.id_pokupatelya)))
  WHERE (users.login = CURRENT_USER))));
 /   DROP POLICY only_pokupateli ON public.prodaji;
       public          postgres    false    220    220    224    224            b           3256    49153    users only_user    POLICY     H   CREATE POLICY only_user ON public.users USING ((login = CURRENT_USER));
 '   DROP POLICY only_user ON public.users;
       public          postgres    false    224    224            c           3256    49154    users only_user_delete    POLICY     Z   CREATE POLICY only_user_delete ON public.users FOR DELETE USING ((login = CURRENT_USER));
 .   DROP POLICY only_user_delete ON public.users;
       public          postgres    false    224    224            d           3256    49155    users only_user_update    POLICY     Z   CREATE POLICY only_user_update ON public.users FOR UPDATE USING ((login = CURRENT_USER));
 .   DROP POLICY only_user_update ON public.users;
       public          postgres    false    224    224            _           0    32789    prodaji    ROW SECURITY     5   ALTER TABLE public.prodaji ENABLE ROW LEVEL SECURITY;          public          postgres    false    220            `           0    32861    users    ROW SECURITY     3   ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;          public          postgres    false    224            j   9   x�3�4估���;.�]ؠpa���v]�qa/�kb��e�i�G��W� �H&�      r     x���MJ�@���S4Y�&Uݕ��Y�$�h`�Dƍ[��������Ną�d\T=���=��ꢮ]tM{I2�ˣQ3�Q����8��W�h�� 	�5y0ʂ%�FE�V]W}1�6�����n��|7���y��ď�_�3��k���t+��ǫ[@ �������8���V���z�U���A�=��	s�xB��Q�=��4=f� m�t`�!��C�P�/��Z����"(��:��N�O'?L�*�RD+����Y      s   #   x�3202�50�54�4�2s�u�9�b���� W&      t   $   x�3202�50�54�4�2s�u�9M�b���� \�?      v   F   x���� �w(&����9AjH�ٵg��a��P�1�7��d�`��꧅��͎�p|Nx�V6�/� s"      p   (  x���1����X�r���7 E7����H/ �Ŏ 3�2>��ź�S�1R�H
��K>�0
�hF�+��XQZ��u��|�-ϒ�z �Xj���S��>p�%��
E����A�z*k�'e����v��1{2D��ݥ#��NQ!w�4mݢ��yJ��t�`!j�|J�񖭧���qg?<7��˞�#��@�mq�)^���S0,d"X�k1�,�kIZ�Mӹ���l������d�O!���y>�[q.��s��r����!����do����Q�~�Z�;��Z      m   !   x�3�440�4202�50�50�2B����� �>      e   %   x� ��1	Колбасный
\.


�5      f   �  x��A�d5��U��ȱc;��X��q�4��,'�!���57�5Ӌ�f�����T������_~��N_}����ݟ^�뇼����0n��.�tw�������$���RQY��$>\������rƫ	��oN���!_$*���p����gǙN�_����˟��.oO�_.o.��7����.���ҫ�`A��0:a��9t,���h����+�����j�r0c�m)[_ H��.����		�	K>��ڤ.AXw�t%X�I�F���%wݣVʶ*�w�q��>8��s�O�а�2�n�Ȓ�c�Y���Tf�Өm{
N/o�˚��ؾ��4`2`e����2��=U�g���sM�2���A��h:i�Nr�X�\+lޭ�1p�zO^>g�43tU��}�fe���@� ����ҩr�O-1��mE�2�r���{���6�rT6hF�+o+�#�#V�)��4؈[���f�lc��,t�=8x�����0�F¤DP���0�Ze���)<皼tu�ku���Y)��`�wZ�d�b�:v]�2F�ݧAo1q�T��4����
9�Ui�#c��F�\y�}=8xٜ��Ó���^:|쁦X]
2ǪvA�<������[�e�G(j��8��\��#�2��EZ�&��,ѣ���5Zp�-���!=�fkY���sŜ�jE*ɨ��o��/��x�@;ͧ"`6�	�&@��憮��L�`�
�vu�׎Vv煢T���Y9�x��YǾI��R��+v5֘b;��9FH����7�=ُ����?�l�&��&�H@��!�T	� i��Ch�� ������j���5�fm�����~co�W�������w�a�����k偭>=*	�&#�T�n�a�#�/����eM�      g   5   x�3�4�440�4202�50�54��*�2+&N�1�����Ȕ+F��� :�      h   a   x�m���0߰K*l������(I�HԊ���
�Bc����(�φ#�g�W�ҚPcᵘ��Yu�I�CB���m�j11쇏z���~?x��P���$c      x   0   x�3�4B##c]C#]#YĈ� ��$�(�X�h�e8�L����� ��+6      k   P   x�%���@�ϡ�>�����툋�b���ĭ��gxչ'���LGI����v�HK[b;(s�����. ?���      n      x�3�440�47�23��+F��� ,a      i   1   x�3�0�¾�/l���b���\F�^��� �]v �b���� i9      l   .   x�3�,-N-2�2Ӧ\&`ڌ�L[p��is.CK0˄+F��� �Fq     