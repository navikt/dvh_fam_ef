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
  json_table(melding, '$?(@.stønadstype != "SKOLEPENGER")'
    COLUMNS (
      BEHANDLINGS_ID  VARCHAR2 PATH '$.behandlingId'
      ,nested path '$.vedtaksperioder[*]' columns (
      fra_og_med      varchar2 path '$.fraOgMed'
      ,til_og_med     varchar2 path '$.tilOgMed'
      ,aktivitet      varchar2 path '$.aktivitet'
      ,periode_type   varchar2 path '$.periodeType'
      ,utgifter       varchar2 path '$.utgifter'
      ,antallbarn     varchar2 path '$.antallBarn'
        )
      )
    ) j
    --where json_value (melding, '$.vedtaksperioder.size()' )> 0
),

final as (
  select
    p.fra_og_med,
    p.til_og_med,
    p.aktivitet,
    p.periode_type,
    p.behandlings_id,
    p.kafka_topic,
    p.kafka_offset,
    p.kafka_partition,
    p.antallbarn,
    p.utgifter,
    pk_EF_FAGSAK as FK_EF_FAGSAK
  from kolonner p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset
  where p.fra_og_med is not null
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_VEDTAKSPERIODER,
  FK_EF_FAGSAK,
  TO_DATE(FRA_OG_MED, 'YYYY-MM-DD') FRA_OG_MED,
  TO_DATE(TIL_OG_MED, 'YYYY-MM-DD') TIL_OG_MED,
  AKTIVITET,
  PERIODE_TYPE,
  BEHANDLINGS_ID,
  KAFKA_TOPIC,
  KAFKA_OFFSET,
  KAFKA_PARTITION,
  localtimestamp AS LASTET_DATO,
  ANTALLBARN,
  UTGIFTER
from final

