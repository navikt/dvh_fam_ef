{{
    config(
        materialized='incremental'
    )
}}

with ef_meta_data as (
  select * from {{ref ('ef_meldinger_til_aa_pakke_ut')}}
),

vedtaksperioder_skole AS (
  SELECT * FROM {{ ref ('fam_ef_vedtaksperioder_skole') }}
),

kolonner as (
  select * from ef_meta_data,
  json_table(melding, '$?(@.stønadstype == "SKOLEPENGER")'
    COLUMNS (
      nested path '$.vedtaksperioder[*]' columns (
      SKOLEAAR     varchar2 path '$.skoleår'
      ,nested path '$.perioder[*]' columns (
      STUDIE_TYPE        varchar2 path '$.studietype'
      ,FRA_OG_MED          varchar2 path '$.datoFra'
      ,TIL_OG_MED          varchar2 path '$.datoTil'
      ,studiebelastning varchar2 path '$.studiebelastning'
        )
      )
      )
    ) j
    --where json_value (melding, '$.vedtaksperioder.perioder.size()' )> 0

),

final as (
  select
    p.STUDIE_TYPE,
    p.FRA_OG_MED,
    p.TIL_OG_MED,
    p.studiebelastning,
    p.kafka_offset,
    PK_EF_VEDTAKSPERIODER_SKOLE as FK_EF_VEDTAKSPERIODER_SKOLE
  from kolonner p
  join vedtaksperioder_skole v
  on p.kafka_offset = v.kafka_offset
  and p.skoleaar = v.skoleaar
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_DELPERIODE_SKOLE,
  STUDIE_TYPE,
  to_date(FRA_OG_MED, 'yyyy-mm-dd') FRA_OG_MED,
  to_date(TIL_OG_MED, 'yyyy-mm-dd') TIL_OG_MED,
  STUDIEBELASTNING,
  localtimestamp as LASTET_DATO,
  FK_EF_VEDTAKSPERIODER_SKOLE,
  kafka_offset
from final


