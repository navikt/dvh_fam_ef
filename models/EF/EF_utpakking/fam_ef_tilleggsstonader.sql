{{
    config(
        materialized='incremental'
    )
}}

with ef_meta_data as (
  select * from {{ref ('ef_meldinger_til_aa_pakke_ut')}}
),

ef_fagsak AS (
  SELECT * FROM {{ ref ('fam_ef_fagsak') }}
),

kolonner_perioder_kontantstotte as (
  select * from ef_meta_data,
  json_table(melding, '$?(@.stønadstype == "BARNETILSYN")'
    COLUMNS (
      nested            path '$.perioderKontantstøtte[*]' columns (
        fra_og_med      varchar2 path '$.fraOgMed',
        til_og_med      varchar2 path '$.tilOgMed',
        belop           varchar2 path '$.beløp'
        )
      )
    )j
    --where json_value (melding, '$.perioderKontantstøtte.size()' )> 0
),

kolonner_perioder_tilleggsstonad as (
  select * from ef_meta_data,
  json_table(melding, '$?(@.stønadstype == "BARNETILSYN")'
    COLUMNS (
      nested            path '$.perioderTilleggsstønad[*]' columns (
        fra_og_med      varchar2 path '$.fraOgMed',
        til_og_med      varchar2 path '$.tilOgMed',
        belop           varchar2 path '$.beløp'
        )
      )
    )j
    --where json_value (melding, '$.perioderTilleggsstønad.size()' )> 0
),

perioder_kontantstotte as (
  select
    'KONTANTSTØTTE' TYPE_TILLEGGS_STONAD,
    TO_DATE(FRA_OG_MED, 'YYYY-MM-DD') FRA_OG_MED,
    TO_DATE(TIL_OG_MED, 'YYYY-MM-DD') TIL_OG_MED,
    belop,
    kafka_offset
  from kolonner_perioder_kontantstotte
),

perioder_tilleggsstonad as (
  select
    'TILLEGG' TYPE_TILLEGGS_STONAD,
    TO_DATE(FRA_OG_MED, 'YYYY-MM-DD') FRA_OG_MED,
    TO_DATE(TIL_OG_MED, 'YYYY-MM-DD') TIL_OG_MED,
    belop,
    kafka_offset
  from kolonner_perioder_tilleggsstonad
),

pre_final as (
  select * from perioder_kontantstotte
  union
  select * from perioder_tilleggsstonad
),

final as (
  select
    p.TYPE_TILLEGGS_STONAD,
    p.FRA_OG_MED,
    p.TIL_OG_MED,
    p.belop,
    pk_EF_FAGSAK as FK_EF_FAGSAK
  from pre_final p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset
  where p.fra_og_med is not null
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as pk_ef_tilleggsstonader,
  fk_ef_fagsak,
  type_tilleggs_stonad,
  fra_og_med,
  til_og_med,
  belop,
  localtimestamp AS lastet_dato
from final

