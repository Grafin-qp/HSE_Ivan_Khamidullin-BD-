--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

-- Started on 2024-02-04 23:20:41

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

--
-- TOC entry 258 (class 1255 OID 16556)
-- Name: add_case_participant(character varying, date, character varying, character varying, character varying, character varying, character varying, date, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_case_participant(p_full_name character varying, p_birth_date date, p_contact_info character varying, p_type character varying, p_inn character varying, p_passport_serial character varying, p_passport_number character varying, p_passport_issue_date date, p_passport_issuing_authority character varying, p_address_registration character varying, p_legal_address character varying, p_general_director_name character varying, p_judge_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Persons (FullName, BirthDate, ContactInfo, Type, INN, PassportSerial, PassportNumber, PassportIssueDate, PassportIssuingAuthority, AddressRegistration, LegalAddress, GeneralDirectorName, JudgeName)
    VALUES (p_full_name, p_birth_date, p_contact_info, p_type, p_inn, p_passport_serial, p_passport_number, p_passport_issue_date, p_passport_issuing_authority, p_address_registration, p_legal_address, p_general_director_name, p_judge_name);
END;
$$;


ALTER FUNCTION public.add_case_participant(p_full_name character varying, p_birth_date date, p_contact_info character varying, p_type character varying, p_inn character varying, p_passport_serial character varying, p_passport_number character varying, p_passport_issue_date date, p_passport_issuing_authority character varying, p_address_registration character varying, p_legal_address character varying, p_general_director_name character varying, p_judge_name character varying) OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 16494)
-- Name: check_inn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_inn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.Type = 'Юридическое лицо' AND (NEW.INN IS NULL OR NEW.INN = '') THEN
    RAISE EXCEPTION 'Для юридического лица необходимо внести ИНН.';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_inn() OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 16496)
-- Name: check_legal_person(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_legal_person() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.Type = 'Юридическое лицо' THEN
    IF NEW.RoleName = 'Судья' THEN
      RAISE EXCEPTION 'Юридическое лицо не может быть судьей.';
    ELSIF NEW.LegalAddress IS NULL OR NEW.OGRN IS NULL OR NEW.CEOName IS NULL THEN
      RAISE EXCEPTION 'Для юридического лица должны быть указаны адрес, ОГРН и имя генерального директора.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_legal_person() OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16500)
-- Name: check_person_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_person_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Если лицо является юридическим, убедиться, что дата рождения не установлена и не является судьей
  IF NEW.Type = 'Юридическое лицо' THEN
    NEW.DateOfBirth = NULL; -- Установка даты рождения в NULL для юридических лиц
    IF NEW.RoleName = 'Судья' THEN
      RAISE EXCEPTION 'Юридическое лицо не может быть судьей.';
    ELSIF NEW.LegalAddress IS NULL OR NEW.OGRN IS NULL OR NEW.CEOName IS NULL OR NEW.INN IS NULL THEN
      RAISE EXCEPTION 'Для юридического лица должны быть указаны юридический адрес, ОГРН, ИНН и имя генерального директора.';
    END IF;
  -- Если лицо является физическим и не судьей, убедиться, что заполнены все необходимые поля
  ELSIF NEW.Type = 'Физическое лицо' AND NEW.RoleName != 'Судья' THEN
    IF NEW.ResidentialAddress IS NULL OR NEW.PassportSeries IS NULL OR NEW.PassportNumber IS NULL 
       OR NEW.PassportIssueDate IS NULL OR NEW.PassportIssuedBy IS NULL THEN
      RAISE EXCEPTION 'Для физического лица, не являющегося судьей, должны быть указаны паспортные данные и адрес прописки.';
    END IF;
  -- Если лицо является судьей, убедиться, что только ФИО и контактная информация заполнены
  ELSIF NEW.RoleName = 'Судья' THEN
    -- Очистка всех полей, кроме ФИО и контактной информации
    NEW.DateOfBirth = NULL;
    NEW.ResidentialAddress = NULL;
    NEW.PassportSeries = NULL;
    NEW.PassportNumber = NULL;
    NEW.PassportIssueDate = NULL;
    NEW.PassportIssuedBy = NULL;
    NEW.LegalAddress = NULL;
    NEW.OGRN = NULL;
    NEW.CEOName = NULL;
    NEW.INN = NULL; -- Добавлено условие очистки ИНН для судьи
    -- Проверка наличия ФИО и контактной информации
    IF NEW.FullName IS NULL OR NEW.ContactInfo IS NULL THEN
      RAISE EXCEPTION 'Для судьи должны быть указаны только ФИО и контактная информация.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_person_details() OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 16497)
-- Name: check_physical_person(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_physical_person() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.Type = 'Физическое лицо' AND NEW.RoleName != 'Судья' THEN
    IF NEW.ResidentialAddress IS NULL OR NEW.PassportSeries IS NULL OR NEW.PassportNumber IS NULL 
       OR NEW.PassportIssueDate IS NULL OR NEW.PassportIssuedBy IS NULL THEN
      RAISE EXCEPTION 'Для физического лица, не являющегося судьей, должны быть указаны паспортные данные и адрес прописки.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_physical_person() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16544)
-- Name: get_average_case_duration(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_average_case_duration() RETURNS TABLE(judgename character varying, averageduration numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT p.FullName, AVG(c.EndDate - c.StartDate)
    FROM Cases c
    JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
    JOIN Persons p ON cp.PersonID = p.PersonID
    JOIN Roles r ON cp.RoleID = r.RoleID
    WHERE r.RoleName = 'Судья'
    GROUP BY p.FullName;
END;
$$;


ALTER FUNCTION public.get_average_case_duration() OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 16554)
-- Name: get_case_category_counts_by_period(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_case_category_counts_by_period(start_date date, end_date date) RETURNS TABLE(periodstart date, periodend date, casecategory character varying, casecount integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH Periods AS (
        SELECT 
            generate_series(start_date, end_date, interval '1 month') AS PeriodStart,
            generate_series(start_date + interval '1 month', end_date + interval '1 month', interval '1 month') AS PeriodEnd
    )
    SELECT 
        p.PeriodStart,
        p.PeriodEnd,
        c.CaseCategory,
        COUNT(*) AS CaseCount
    FROM 
        Cases c
        JOIN Periods p ON c.CaseDate >= p.PeriodStart AND c.CaseDate < p.PeriodEnd
    GROUP BY 
        p.PeriodStart, p.PeriodEnd, c.CaseCategory
    ORDER BY 
        p.PeriodStart, p.PeriodEnd, c.CaseCategory;
END;
$$;


ALTER FUNCTION public.get_case_category_counts_by_period(start_date date, end_date date) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16543)
-- Name: get_cases_by_judge(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_cases_by_judge(judge_name character varying) RETURNS TABLE(casename character varying, description text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT c.CaseName, c.Description
    FROM Cases c
    JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
    JOIN Persons p ON cp.PersonID = p.PersonID
    JOIN Roles r ON cp.RoleID = r.RoleID
    WHERE p.FullName = judge_name AND r.RoleName = 'Судья';
END;
$$;


ALTER FUNCTION public.get_cases_by_judge(judge_name character varying) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16542)
-- Name: get_cases_by_person(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_cases_by_person(person_name character varying) RETURNS TABLE(casename character varying, description text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT c.CaseName, c.Description
    FROM Cases c
    JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
    JOIN Persons p ON cp.PersonID = p.PersonID
    WHERE p.FullName = person_name;
END;
$$;


ALTER FUNCTION public.get_cases_by_person(person_name character varying) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 16555)
-- Name: get_efficient_judicial_districts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_efficient_judicial_districts() RETURNS TABLE(judicialdistrictname character varying, casecategory character varying, averageduration integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH JudicialDistricts AS (
        SELECT DISTINCT JudicialDistrictName FROM Cases
    )
    SELECT 
        jd.JudicialDistrictName,
        c.CaseCategory,
        AVG(c.Duration) AS AverageDuration
    FROM 
        Cases c
        JOIN JudicialDistricts jd ON c.JudicialDistrictName = jd.JudicialDistrictName
    GROUP BY 
        jd.JudicialDistrictName, c.CaseCategory
    HAVING 
        AVG(c.Duration) < (
            SELECT 
                AVG(Duration) AS GlobalAverage
            FROM 
                Cases
        )
    ORDER BY 
        jd.JudicialDistrictName, c.CaseCategory, AverageDuration;
END;
$$;


ALTER FUNCTION public.get_efficient_judicial_districts() OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16545)
-- Name: get_judges_by_case_count(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_judges_by_case_count(last_year_count integer) RETURNS TABLE(judgename character varying, casescount integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT p.FullName, COUNT(c.CaseID)
    FROM Cases c
    JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
    JOIN Persons p ON cp.PersonID = p.PersonID
    JOIN Roles r ON cp.RoleID = r.RoleID
    WHERE c.StartDate >= CURRENT_DATE - INTERVAL '1 year' AND r.RoleName = 'Судья'
    GROUP BY p.FullName
    HAVING COUNT(c.CaseID) > last_year_count;
END;
$$;


ALTER FUNCTION public.get_judges_by_case_count(last_year_count integer) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16546)
-- Name: get_judges_success_rate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_judges_success_rate() RETURNS TABLE(judgename character varying, successfulcases integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT p.FullName, COUNT(c.CaseID) as SuccessfulCases
    FROM Cases c
    JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
    JOIN Persons p ON cp.PersonID = p.PersonID
    JOIN Roles r ON cp.RoleID = r.RoleID
    WHERE r.RoleName = 'Судья' AND (c.CaseOutcome = 'Удовлетворено' OR c.CaseOutcome = 'Удовлетворено частично')
    GROUP BY p.FullName
    ORDER BY SuccessfulCases DESC;
END;
$$;


ALTER FUNCTION public.get_judges_success_rate() OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16551)
-- Name: get_legal_entities_winning_majority(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_legal_entities_winning_majority(p_category character varying) RETURNS TABLE(legalentityname character varying, totalcases integer, woncases integer, category character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH LegalCases AS (
        SELECT 
            p.PersonID,
            p.FullName AS LegalEntityName,
            COUNT(c.CaseID) AS TotalCases,
            SUM(CASE WHEN c.WinningSide = 'Истец' THEN 1 ELSE 0 END) AS WonCases,
            c.CaseCategory
        FROM 
            Cases c
            JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
            JOIN Persons p ON cp.PersonID = p.PersonID AND p.Type = 'Юридическое лицо'
        WHERE 
            c.CaseCategory = p_category
        GROUP BY 
            p.PersonID, c.CaseCategory
    )
    SELECT 
        LegalEntityName,
        TotalCases,
        WonCases,
        CaseCategory AS Category
    FROM 
        LegalCases
    WHERE 
        (WonCases::DECIMAL / TotalCases) > 0.5;
END;
$$;


ALTER FUNCTION public.get_legal_entities_winning_majority(p_category character varying) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 16552)
-- Name: get_negative_decision_categories(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_negative_decision_categories() RETURNS TABLE(categoryname character varying, negativedecisionratio numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH CategoryCounts AS (
        SELECT 
            c.CaseCategory AS CategoryName,
            COUNT(*) AS TotalCases,
            SUM(CASE WHEN c.CaseOutcome = 'Отказано в удовлетворении' THEN 1 ELSE 0 END) AS NegativeDecisions
        FROM 
            Cases c
        GROUP BY 
            c.CaseCategory
    )
    SELECT 
        cc.CategoryName,
        (cc.NegativeDecisions::DECIMAL / cc.TotalCases) AS NegativeDecisionRatio
    FROM 
        CategoryCounts cc
    ORDER BY 
        NegativeDecisionRatio DESC;
END;
$$;


ALTER FUNCTION public.get_negative_decision_categories() OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 16553)
-- Name: get_persons_and_judges_with_all_wins(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_persons_and_judges_with_all_wins() RETURNS TABLE(personname character varying, judgename character varying, casecategory character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH AllWins AS (
        SELECT 
            cp.PersonID,
            p.FullName AS PersonName,
            c.JudgeName,
            c.CaseCategory
        FROM 
            Cases c
            JOIN CaseParticipants cp ON c.CaseID = cp.CaseID
            JOIN Persons p ON cp.PersonID = p.PersonID AND p.Type = 'Физическое лицо'
        WHERE 
            c.WinningSide = 'Истец'
        GROUP BY 
            cp.PersonID, p.FullName, c.JudgeName, c.CaseCategory
        HAVING 
            COUNT(*) = SUM(CASE WHEN c.WinningSide = 'Истец' THEN 1 ELSE 0 END)
    )
    SELECT 
        PersonName,
        JudgeName,
        CaseCategory
    FROM 
        AllWins;
END;
$$;


ALTER FUNCTION public.get_persons_and_judges_with_all_wins() OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16547)
-- Name: set_winning_side(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_winning_side() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.CaseOutcome = 'Удовлетворено' OR NEW.CaseOutcome = 'Удовлетворено частично' THEN
        NEW.WinningSide := 'Истец';
    ELSIF NEW.CaseOutcome = 'Отказано в удовлетворении' THEN
        NEW.WinningSide := 'Ответчик';
    ELSE
        NEW.WinningSide := NULL; -- В случаях, если исход не определен
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_winning_side() OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 16557)
-- Name: update_contact_info(character varying, date, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_contact_info(p_full_name character varying, p_birth_date date, p_identification_data character varying, p_new_email character varying, p_new_phone_number character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Persons
    SET
        ContactInfo = COALESCE(p_new_email, ContactInfo),
        PhoneNumber = COALESCE(p_new_phone_number, PhoneNumber)
    WHERE
        FullName = p_full_name
        AND BirthDate = p_birth_date
        AND (INN = p_identification_data OR PassportSerial || PassportNumber = p_identification_data);
END;
$$;


ALTER FUNCTION public.update_contact_info(p_full_name character varying, p_birth_date date, p_identification_data character varying, p_new_email character varying, p_new_phone_number character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 16439)
-- Name: caseparticipants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caseparticipants (
    participationid integer NOT NULL,
    caseid integer NOT NULL,
    personid integer NOT NULL,
    roleid integer NOT NULL
);


ALTER TABLE public.caseparticipants OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16438)
-- Name: caseparticipants_participationid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caseparticipants_participationid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.caseparticipants_participationid_seq OWNER TO postgres;

--
-- TOC entry 4956 (class 0 OID 0)
-- Dependencies: 221
-- Name: caseparticipants_participationid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caseparticipants_participationid_seq OWNED BY public.caseparticipants.participationid;


--
-- TOC entry 220 (class 1259 OID 16430)
-- Name: cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cases (
    caseid integer NOT NULL,
    casename character varying(255) NOT NULL,
    description text,
    startdate date,
    enddate date,
    status character varying(50),
    casecategory character varying(255),
    caseoutcome character varying(255),
    winningside character varying(255),
    CONSTRAINT cases_caseoutcome_check CHECK (((caseoutcome)::text = ANY ((ARRAY['Удовлетворено'::character varying, 'Удовлетворено частично'::character varying, 'Отказано в удовлетворении'::character varying])::text[])))
);


ALTER TABLE public.cases OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16429)
-- Name: cases_caseid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cases_caseid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cases_caseid_seq OWNER TO postgres;

--
-- TOC entry 4957 (class 0 OID 0)
-- Dependencies: 219
-- Name: cases_caseid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cases_caseid_seq OWNED BY public.cases.caseid;


--
-- TOC entry 230 (class 1259 OID 16511)
-- Name: courts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courts (
    courtid integer NOT NULL,
    courtname character varying(255) NOT NULL,
    districtid integer NOT NULL
);


ALTER TABLE public.courts OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16510)
-- Name: courts_courtid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.courts_courtid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.courts_courtid_seq OWNER TO postgres;

--
-- TOC entry 4958 (class 0 OID 0)
-- Dependencies: 229
-- Name: courts_courtid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.courts_courtid_seq OWNED BY public.courts.courtid;


--
-- TOC entry 224 (class 1259 OID 16461)
-- Name: documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documents (
    documentid integer NOT NULL,
    caseid integer NOT NULL,
    documentname character varying(255) NOT NULL,
    documenttype character varying(50),
    creationdate date,
    content text,
    CONSTRAINT chk_document_date CHECK (((creationdate <= CURRENT_DATE) AND (creationdate > '1900-01-01'::date)))
);


ALTER TABLE public.documents OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16460)
-- Name: documents_documentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.documents_documentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documents_documentid_seq OWNER TO postgres;

--
-- TOC entry 4959 (class 0 OID 0)
-- Dependencies: 223
-- Name: documents_documentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.documents_documentid_seq OWNED BY public.documents.documentid;


--
-- TOC entry 226 (class 1259 OID 16475)
-- Name: hearings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hearings (
    hearingid integer NOT NULL,
    caseid integer NOT NULL,
    datetime timestamp without time zone NOT NULL,
    location character varying(255),
    decision text
);


ALTER TABLE public.hearings OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16474)
-- Name: hearings_hearingid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hearings_hearingid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hearings_hearingid_seq OWNER TO postgres;

--
-- TOC entry 4960 (class 0 OID 0)
-- Dependencies: 225
-- Name: hearings_hearingid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hearings_hearingid_seq OWNED BY public.hearings.hearingid;


--
-- TOC entry 231 (class 1259 OID 16527)
-- Name: judges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.judges (
    judgeid integer NOT NULL,
    courtid integer NOT NULL
);


ALTER TABLE public.judges OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16504)
-- Name: judicialdistricts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.judicialdistricts (
    districtid integer NOT NULL,
    districtname character varying(255) NOT NULL
);


ALTER TABLE public.judicialdistricts OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16503)
-- Name: judicialdistricts_districtid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.judicialdistricts_districtid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.judicialdistricts_districtid_seq OWNER TO postgres;

--
-- TOC entry 4961 (class 0 OID 0)
-- Dependencies: 227
-- Name: judicialdistricts_districtid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.judicialdistricts_districtid_seq OWNED BY public.judicialdistricts.districtid;


--
-- TOC entry 216 (class 1259 OID 16414)
-- Name: persons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.persons (
    personid integer NOT NULL,
    fullname character varying(255) NOT NULL,
    dateofbirth date,
    type character varying(50) NOT NULL,
    contactinfo text,
    inn character varying(12),
    residentialaddress text,
    passportseries character varying(4),
    passportnumber character varying(6),
    passportissuedate date,
    passportissuedby text,
    legaladdress text,
    ogrn character varying(13),
    ceoname character varying(255),
    courtid integer,
    rolename character varying(255),
    CONSTRAINT chk_person_type CHECK (((type)::text = ANY ((ARRAY['Физическое лицо'::character varying, 'Юридическое лицо'::character varying])::text[])))
);


ALTER TABLE public.persons OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16413)
-- Name: persons_personid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.persons_personid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.persons_personid_seq OWNER TO postgres;

--
-- TOC entry 4962 (class 0 OID 0)
-- Dependencies: 215
-- Name: persons_personid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.persons_personid_seq OWNED BY public.persons.personid;


--
-- TOC entry 218 (class 1259 OID 16423)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    roleid integer NOT NULL,
    rolename character varying(255) NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16422)
-- Name: roles_roleid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_roleid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_roleid_seq OWNER TO postgres;

--
-- TOC entry 4963 (class 0 OID 0)
-- Dependencies: 217
-- Name: roles_roleid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_roleid_seq OWNED BY public.roles.roleid;


--
-- TOC entry 4747 (class 2604 OID 16442)
-- Name: caseparticipants participationid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caseparticipants ALTER COLUMN participationid SET DEFAULT nextval('public.caseparticipants_participationid_seq'::regclass);


--
-- TOC entry 4746 (class 2604 OID 16433)
-- Name: cases caseid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cases ALTER COLUMN caseid SET DEFAULT nextval('public.cases_caseid_seq'::regclass);


--
-- TOC entry 4751 (class 2604 OID 16514)
-- Name: courts courtid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts ALTER COLUMN courtid SET DEFAULT nextval('public.courts_courtid_seq'::regclass);


--
-- TOC entry 4748 (class 2604 OID 16464)
-- Name: documents documentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents ALTER COLUMN documentid SET DEFAULT nextval('public.documents_documentid_seq'::regclass);


--
-- TOC entry 4749 (class 2604 OID 16478)
-- Name: hearings hearingid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hearings ALTER COLUMN hearingid SET DEFAULT nextval('public.hearings_hearingid_seq'::regclass);


--
-- TOC entry 4750 (class 2604 OID 16507)
-- Name: judicialdistricts districtid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.judicialdistricts ALTER COLUMN districtid SET DEFAULT nextval('public.judicialdistricts_districtid_seq'::regclass);


--
-- TOC entry 4744 (class 2604 OID 16417)
-- Name: persons personid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persons ALTER COLUMN personid SET DEFAULT nextval('public.persons_personid_seq'::regclass);


--
-- TOC entry 4745 (class 2604 OID 16426)
-- Name: roles roleid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN roleid SET DEFAULT nextval('public.roles_roleid_seq'::regclass);


--
-- TOC entry 4941 (class 0 OID 16439)
-- Dependencies: 222
-- Data for Name: caseparticipants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caseparticipants (participationid, caseid, personid, roleid) FROM stdin;
5	1	101	2
6	1	202	3
\.


--
-- TOC entry 4939 (class 0 OID 16430)
-- Dependencies: 220
-- Data for Name: cases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cases (caseid, casename, description, startdate, enddate, status, casecategory, caseoutcome, winningside) FROM stdin;
1	Банкротсво века	Банкротный спор между... и ... бла бла	2019-12-01	2021-12-01	Завершен	Банктный	Удовлетворено	Истец
\.


--
-- TOC entry 4949 (class 0 OID 16511)
-- Dependencies: 230
-- Data for Name: courts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courts (courtid, courtname, districtid) FROM stdin;
\.


--
-- TOC entry 4943 (class 0 OID 16461)
-- Dependencies: 224
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documents (documentid, caseid, documentname, documenttype, creationdate, content) FROM stdin;
\.


--
-- TOC entry 4945 (class 0 OID 16475)
-- Dependencies: 226
-- Data for Name: hearings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hearings (hearingid, caseid, datetime, location, decision) FROM stdin;
\.


--
-- TOC entry 4950 (class 0 OID 16527)
-- Dependencies: 231
-- Data for Name: judges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.judges (judgeid, courtid) FROM stdin;
\.


--
-- TOC entry 4947 (class 0 OID 16504)
-- Dependencies: 228
-- Data for Name: judicialdistricts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.judicialdistricts (districtid, districtname) FROM stdin;
\.


--
-- TOC entry 4935 (class 0 OID 16414)
-- Dependencies: 216
-- Data for Name: persons; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.persons (personid, fullname, dateofbirth, type, contactinfo, inn, residentialaddress, passportseries, passportnumber, passportissuedate, passportissuedby, legaladdress, ogrn, ceoname, courtid, rolename) FROM stdin;
202	ООО "Рога и Копыта"	\N	Юридическое лицо	sorry@helpa.net	123412341234	\N	\N	\N	\N	\N	Москва, ул. Шестакова, д. 12, оф. 5	1231231231234	Иванов Иван Иванович	\N	Ответчик
101	Петров Иван Васильевич	1985-01-30	Физическое лицо	help@me.ru	\N	Москва, ул. Попова, д. 16, кв. 5	1234	123456	2012-01-23	МВД	\N	\N	\N	\N	Истец
\.


--
-- TOC entry 4937 (class 0 OID 16423)
-- Dependencies: 218
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (roleid, rolename) FROM stdin;
1	Судья
2	Истец
3	Ответчик
4	Третье лицо
\.


--
-- TOC entry 4964 (class 0 OID 0)
-- Dependencies: 221
-- Name: caseparticipants_participationid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caseparticipants_participationid_seq', 1, false);


--
-- TOC entry 4965 (class 0 OID 0)
-- Dependencies: 219
-- Name: cases_caseid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cases_caseid_seq', 1, false);


--
-- TOC entry 4966 (class 0 OID 0)
-- Dependencies: 229
-- Name: courts_courtid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.courts_courtid_seq', 1, false);


--
-- TOC entry 4967 (class 0 OID 0)
-- Dependencies: 223
-- Name: documents_documentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.documents_documentid_seq', 1, false);


--
-- TOC entry 4968 (class 0 OID 0)
-- Dependencies: 225
-- Name: hearings_hearingid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hearings_hearingid_seq', 1, false);


--
-- TOC entry 4969 (class 0 OID 0)
-- Dependencies: 227
-- Name: judicialdistricts_districtid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.judicialdistricts_districtid_seq', 1, false);


--
-- TOC entry 4970 (class 0 OID 0)
-- Dependencies: 215
-- Name: persons_personid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.persons_personid_seq', 1, false);


--
-- TOC entry 4971 (class 0 OID 0)
-- Dependencies: 217
-- Name: roles_roleid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_roleid_seq', 4, true);


--
-- TOC entry 4764 (class 2606 OID 16444)
-- Name: caseparticipants caseparticipants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caseparticipants
    ADD CONSTRAINT caseparticipants_pkey PRIMARY KEY (participationid);


--
-- TOC entry 4762 (class 2606 OID 16437)
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (caseid);


--
-- TOC entry 4774 (class 2606 OID 16516)
-- Name: courts courts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_pkey PRIMARY KEY (courtid);


--
-- TOC entry 4766 (class 2606 OID 16468)
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (documentid);


--
-- TOC entry 4770 (class 2606 OID 16482)
-- Name: hearings hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hearings
    ADD CONSTRAINT hearings_pkey PRIMARY KEY (hearingid);


--
-- TOC entry 4776 (class 2606 OID 16531)
-- Name: judges judges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.judges
    ADD CONSTRAINT judges_pkey PRIMARY KEY (judgeid);


--
-- TOC entry 4772 (class 2606 OID 16509)
-- Name: judicialdistricts judicialdistricts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.judicialdistricts
    ADD CONSTRAINT judicialdistricts_pkey PRIMARY KEY (districtid);


--
-- TOC entry 4756 (class 2606 OID 16421)
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (personid);


--
-- TOC entry 4760 (class 2606 OID 16428)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (roleid);


--
-- TOC entry 4768 (class 2606 OID 16492)
-- Name: documents unq_document_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT unq_document_name UNIQUE (documentname);


--
-- TOC entry 4758 (class 2606 OID 16490)
-- Name: persons unq_fullname; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT unq_fullname UNIQUE (fullname);


--
-- TOC entry 4786 (class 2620 OID 16495)
-- Name: persons trg_check_inn_before_insert_or_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_inn_before_insert_or_update BEFORE INSERT OR UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.check_inn();


--
-- TOC entry 4787 (class 2620 OID 16499)
-- Name: persons trg_check_legal_person_before_insert_or_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_legal_person_before_insert_or_update BEFORE INSERT OR UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.check_legal_person();


--
-- TOC entry 4788 (class 2620 OID 16501)
-- Name: persons trg_check_person_details_before_insert_or_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_person_details_before_insert_or_update BEFORE INSERT OR UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.check_person_details();


--
-- TOC entry 4789 (class 2620 OID 16498)
-- Name: persons trg_check_physical_person_before_insert_or_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_physical_person_before_insert_or_update BEFORE INSERT OR UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.check_physical_person();


--
-- TOC entry 4790 (class 2620 OID 16548)
-- Name: cases trigger_set_winning_side; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_set_winning_side BEFORE INSERT OR UPDATE ON public.cases FOR EACH ROW EXECUTE FUNCTION public.set_winning_side();


--
-- TOC entry 4778 (class 2606 OID 16445)
-- Name: caseparticipants caseparticipants_caseid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caseparticipants
    ADD CONSTRAINT caseparticipants_caseid_fkey FOREIGN KEY (caseid) REFERENCES public.cases(caseid);


--
-- TOC entry 4779 (class 2606 OID 16450)
-- Name: caseparticipants caseparticipants_personid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caseparticipants
    ADD CONSTRAINT caseparticipants_personid_fkey FOREIGN KEY (personid) REFERENCES public.persons(personid);


--
-- TOC entry 4780 (class 2606 OID 16455)
-- Name: caseparticipants caseparticipants_roleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caseparticipants
    ADD CONSTRAINT caseparticipants_roleid_fkey FOREIGN KEY (roleid) REFERENCES public.roles(roleid);


--
-- TOC entry 4783 (class 2606 OID 16517)
-- Name: courts courts_districtid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_districtid_fkey FOREIGN KEY (districtid) REFERENCES public.judicialdistricts(districtid);


--
-- TOC entry 4781 (class 2606 OID 16469)
-- Name: documents documents_caseid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_caseid_fkey FOREIGN KEY (caseid) REFERENCES public.cases(caseid);


--
-- TOC entry 4782 (class 2606 OID 16483)
-- Name: hearings hearings_caseid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hearings
    ADD CONSTRAINT hearings_caseid_fkey FOREIGN KEY (caseid) REFERENCES public.cases(caseid);


--
-- TOC entry 4784 (class 2606 OID 16537)
-- Name: judges judges_courtid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.judges
    ADD CONSTRAINT judges_courtid_fkey FOREIGN KEY (courtid) REFERENCES public.courts(courtid);


--
-- TOC entry 4785 (class 2606 OID 16532)
-- Name: judges judges_judgeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.judges
    ADD CONSTRAINT judges_judgeid_fkey FOREIGN KEY (judgeid) REFERENCES public.persons(personid);


--
-- TOC entry 4777 (class 2606 OID 16522)
-- Name: persons persons_courtid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_courtid_fkey FOREIGN KEY (courtid) REFERENCES public.courts(courtid);


-- Completed on 2024-02-04 23:20:42

--
-- PostgreSQL database dump complete
--

