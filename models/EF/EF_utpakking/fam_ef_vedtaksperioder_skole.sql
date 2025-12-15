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

kolonner as (
select * from ef_meta_data,
  json_table(melding, '$?(@.stønadstype == "SKOLEPENGER")'
    COLUMNS (
      nested                    path '$.vedtaksperioder[*]' columns (
      skoleaar                  varchar2 path '$.skoleår'
      ,maks_sats_for_skoleaar    varchar2 path '$.maksSatsForSkoleår'
      )
    )
  ) j
  --where json_value (melding, '$.vedtaksperioder.size()' )> 0
),

final as (
  select
    p.SKOLEAAR,
    p.MAKS_SATS_FOR_SKOLEAAR,
    p.kafka_offset,
    pk_EF_FAGSAK as FK_EF_FAGSAK
  from kolonner p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_VEDTAKSPERIODER_SKOLE,
  SKOLEAAR,
  MAKS_SATS_FOR_SKOLEAAR,
  localtimestamp AS lastet_dato,
  FK_EF_FAGSAK,
  kafka_offset
from final
