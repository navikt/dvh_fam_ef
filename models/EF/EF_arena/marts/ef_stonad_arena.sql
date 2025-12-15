WITH fak_stonad_ AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_fak_stonad') }}
),

dim_omraade AS(
    SELECT *  --pk_dim_f_stonad_omraade, stonad_kode
    FROM
        {{ ref ('stg_fam_ef_arena_dim_omraade') }}
    --WHERE
        --stonad_kode IN ('TSOBOUTG', 'TSODAGREIS', 'TSOFLYTT', 'TSOLMIDLER', 'TSOREISAKT', 'TSOREISARB',
            --'TSOREISOBL', 'TSOTILBARN', 'TSOTILFAM')
),

person AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_person') }}
),

person_kontaktinfo AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_person_k_info') }}
),

dim_kjonn_ AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_kjonn') }}
),

dim_alder_ AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_alder') }}
),

dim_maalgruppe_type_ AS (
    SELECT *
        --pk_dim_maalgruppe_type,
        --maalgruppe_kode,
        --maalgruppe_navn_scd1

    FROM
        {{ ref ('stg_fam_ef_arena_dim_maalgruppe') }}
    --WHERE
        --maalgruppe_kode IN ('ENSFORUTD', 'ENSFORARBS', 'TIDLFAMPL', 'GJENEKUTD', 'GJENEKARBS')
),

dim_vedtak_postering_ AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_vedtak_postering' ) }}
),

dim_geo AS (
    SELECT * FROM {{ ref ('stg_fam_ef_arena_dim_geo') }}
),

FINAL AS (
    SELECT

        --( SELECT to_char(ADD_MONTHS(SYSDATE, -1), 'YYYYMM') FROM dual) periode,
        '{{ var ("periode") }}' AS periode,
        fs.lk_postering_id,
        max(ald.alder) over (PARTITION by fs.fk_person1) alder,
        so.stonad_kode,
        geo.kommune_nr,
        geo.bydel_nr,
        geo.pk_dim_geografi,
        kjonn.kjonn_kode,
        maalt.maalgruppe_kode,
        maalt.maalgruppe_navn_scd1 AS maalgruppe_navn,
        per.statsborgerskap,
        per.fodeland,
        per.sivilstatus_kode,
        per.barn_under_18_antall,
        fs.fk_person1,
        fs.fk_dim_person,
        vp.antblav,
        vp.antbhoy,
        fs.postert_dato,
        fs.fk_dim_tid_postering_fra_dato AS postering_fra_dato,
        fs.fk_dim_tid_postering_til_dato AS postering_til_dato,
        fs.inntekt_siste_beraar,
        fs.inntekt_3_siste_beraar,
        dtp.fodselsnummer_gjeldende,
        fs.postert_belop
    FROM
        fak_stonad_ fs
        JOIN dim_omraade so
        ON fs.fk_dim_f_stonad_omraade = so.pk_dim_f_stonad_omraade
        JOIN dim_maalgruppe_type_ maalt
        ON fs.fk_dim_maalgruppe_type = maalt.pk_dim_maalgruppe_type

        JOIN person per
        ON fs.fk_dim_person = per.pk_dim_person
        --and per.gyldig_fra_dato <= last_day(fs.postert_dato)
        --and per.gyldig_til_dato >= last_day(fs.postert_dato)

        left JOIN person_kontaktinfo dtp
        ON per.fk_person1 = dtp.fk_person1
        JOIN dim_kjonn_ kjonn
        ON fs.fk_dim_kjonn = kjonn.pk_dim_kjonn
        JOIN dim_alder_ ald
        ON fs.fk_dim_alder = ald.pk_dim_alder
        JOIN dim_vedtak_postering_ vp
        ON fs.fk_dim_vedtak_postering = vp.pk_dim_vedtak_postering
        JOIN dim_geo geo
        ON fs.fk_dim_geografi_bosted = geo.pk_dim_geografi
    WHERE
        TRUNC(fs.postert_dato) >= TO_DATE('{{ var ("periode") }}' || '01', 'yyyymmdd')
        AND TRUNC(
            fs.postert_dato
        ) <= LAST_DAY(TO_DATE('{{ var ("periode") }}' || '01', 'yyyymmdd')))


SELECT
  *
FROM
  FINAL





