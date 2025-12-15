{{
    config(
        materialized = 'incremental',
        unique_key = 'periode',
        incremental_strategy='delete+insert',
    )
}}

WITH ef_stonad_arena_agg_per_pvt_ AS (
  SELECT * FROM {{ ref ('ef_stonad_arena_agg_per_pvt') }}
),

ef_stonad_arena_ AS (
  SELECT * FROM {{ ref ('ef_stonad_arena') }}
),

barntrygd_data AS (
  SELECT * FROM {{ ref ('stg_fam_bt_barn') }}
),

legg_til_utdanningsstonad AS (
  SELECT
    fk_person1,
    periode,
    fk_dim_person,
    alder,
    kommune_nr,
    pk_dim_geografi as fk_dim_geografi,
    bydel_nr,
    kjonn_kode,
    maalgruppe_kode,
    maalgruppe_navn,
    statsborgerskap,
    fodeland,
    sivilstatus_kode,
    antblav,
    antbhoy,
    barn_under_18_antall,
    inntekt_siste_beraar,
    inntekt_3_siste_beraar,

    CASE
      WHEN maalgruppe_kode IN ('ENSFORUTD','TIDLFAMPL','GJENEKUTD') THEN COALESCE(tsoboutg,0) + COALESCE(tsodagreis,0) + COALESCE(tsolmidler,0) + COALESCE(tsoreisakt,0) + COALESCE(tsoreisarb,0) + COALESCE(tsoreisobl,0)
    END AS utdstonad,

    tsotilbarn,
    tsolmidler,
    tsoboutg,
    tsodagreis,
    tsoreisobl,
    tsoflytt,
    tsoreisakt,
    tsoreisarb,
    tsotilfam
  FROM
    ef_stonad_arena_agg_per_pvt_
),
barn_data_koloner AS (
  SELECT
    ef_stonad_arena_.fk_person1,
    MIN(NVL(CASE WHEN FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm'))) / 12) < 0 THEN 0
    ELSE FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm'))) / 12)
    END,0)) ybarn,

    COUNT(DISTINCT bt_d.fkb_person1) antbarn,

    COUNT(DISTINCT CASE WHEN FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm'))) / 12) < 1 THEN bt_d.fkb_person1
    ELSE NULL
    END) antbu1,

    COUNT(DISTINCT CASE WHEN FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm'))) / 12) < 3 THEN bt_d.fkb_person1
    ELSE NULL
    END) antbu3,

    COUNT( DISTINCT CASE WHEN FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY( TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm')) ) / 12) < 8 THEN bt_d.fkb_person1
    ELSE NULL
    END) antbu8,

    COUNT( DISTINCT CASE WHEN FLOOR( months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE( bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm' ))) / 12 ) < 10 THEN bt_d.fkb_person1
    ELSE NULL
    END) antbu10,

    COUNT( DISTINCT CASE WHEN FLOOR(months_between(LAST_DAY(TO_DATE(ef_stonad_arena_.periode, 'yyyymm')),LAST_DAY(TO_DATE(bt_d.fodsel_aar_barn || bt_d.fodsel_mnd_barn,'yyyymm'))) / 12) < 18 THEN bt_d.fkb_person1
    ELSE NULL
    END) antbu18

  FROM

    ef_stonad_arena_
    LEFT JOIN barntrygd_data bt_d
    ON ef_stonad_arena_.fk_person1 = bt_d.fk_person1
    AND ef_stonad_arena_.periode = bt_d.stat_aarmnd
  GROUP BY
    ef_stonad_arena_.fk_person1
),

final AS (
  SELECT
    utdstnd.*,
    bdk.antbarn,
    bdk.ybarn,
    bdk.antbu1,
    bdk.antbu3,
    bdk.antbu8,
    bdk.antbu10,
    bdk.antbu18,
    'ARENA' as kildesystem,
    localtimestamp lastet_dato,
    0 as ALDER_GML,
    localtimestamp oppdatert_dato

  FROM
    legg_til_utdanningsstonad utdstnd
    JOIN barn_data_koloner bdk
    ON utdstnd.fk_person1 = bdk.fk_person1
  ORDER BY
    utdstnd.fk_person1
)


SELECT
  DVH_FAM_EF.ISEQ$$_18277021.nextval AS PK_FAM_EF_STONAD_ARENA
  ,cast(null as varchar2(4)) FODSEL_AAR
  ,cast(null as varchar2(4)) FODSEL_MND
  ,FK_PERSON1
  ,FK_DIM_PERSON
  ,PERIODE
  ,ALDER
  ,KOMMUNE_NR
  ,BYDEL_NR
  ,KJONN_KODE
  ,MAALGRUPPE_KODE
  ,MAALGRUPPE_NAVN
  ,STATSBORGERSKAP
  ,FODELAND
  ,SIVILSTATUS_KODE
  ,ANTBLAV
  ,ANTBHOY
  ,BARN_UNDER_18_ANTALL
  ,INNTEKT_SISTE_BERAAR
  ,INNTEKT_3_SISTE_BERAAR
  ,UTDSTONAD
  ,TSOTILBARN
  ,TSOLMIDLER
  ,TSOBOUTG
  ,TSODAGREIS
  ,TSOREISOBL
  ,TSOFLYTT
  ,TSOREISAKT
  ,TSOREISARB
  ,TSOTILFAM
  ,YBARN
  ,ANTBARN
  ,ANTBU1
  ,ANTBU3
  ,ANTBU8
  ,ANTBU10
  ,ANTBU18
  ,KILDESYSTEM
  ,LASTET_DATO
  ,cast(null as varchar2(30)) ALDER_GML
  ,OPPDATERT_DATO
  ,FK_DIM_GEOGRAFI
FROM
 final

{% if is_incremental() %}

where lastet_dato > (select max(lastet_dato) from {{ this }} where kildesystem = 'ARENA')

{% endif %}



