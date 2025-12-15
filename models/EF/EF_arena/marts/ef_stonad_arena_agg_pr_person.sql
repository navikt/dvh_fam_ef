WITH ef_stonad_arena_ AS (
  SELECT * FROM {{ ref ('ef_stonad_arena') }}
),

FINAL AS (
  SELECT
    periode,
    alder,
    postert_dato,
    stonad_kode,
    kommune_nr,
    pk_dim_geografi,
    bydel_nr,
    kjonn_kode,
    max(fk_dim_person) keep (dense_rank first order by postert_dato desc) fk_dim_person,
    fk_person1,
    maalgruppe_kode,
    maalgruppe_navn,
    statsborgerskap,
    fodeland,
    sivilstatus_kode,
    MAX(antblav) AS antblav,
    MAX(antbhoy) AS antbhoy,
    barn_under_18_antall,
    inntekt_siste_beraar,
    inntekt_3_siste_beraar,
    fodselsnummer_gjeldende,
    SUM(postert_belop) AS postert_belop
  FROM
    ef_stonad_arena_
  GROUP BY
    periode,
    alder,
    stonad_kode,
    postert_dato,
    kommune_nr,
    bydel_nr,
    pk_dim_geografi,
    kjonn_kode,
    maalgruppe_kode,
    maalgruppe_navn,
    statsborgerskap,
    fodeland,
    sivilstatus_kode,
    barn_under_18_antall,
    inntekt_siste_beraar,
    inntekt_3_siste_beraar,
    fodselsnummer_gjeldende,
    fk_person1
  ORDER BY
    periode,
    alder,
    kommune_nr,
    bydel_nr,
    pk_dim_geografi,
    kjonn_kode,
    maalgruppe_kode,
    maalgruppe_navn,
    statsborgerskap,
    fodeland,
    sivilstatus_kode,
    barn_under_18_antall,
    inntekt_siste_beraar,
    inntekt_3_siste_beraar,
    fodselsnummer_gjeldende,
    fk_dim_person,
    fk_person1
)
SELECT
  *
FROM
  FINAL
  
