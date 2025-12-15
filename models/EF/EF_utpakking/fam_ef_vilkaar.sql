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

pre_final as (
select * from ef_meta_data,
  json_table(melding, '$'
    COLUMNS (
      BEHANDLINGS_ID  VARCHAR2 PATH '$.behandlingId'
      ,nested path  '$.vilkårsvurderinger[*]' columns (
      vilkaar      varchar2 path '$.vilkår'
      ,resultat     varchar2 path '$.resultat'
        )
      )
    ) j
),

final as (
  select
    p.VILKAAR,
    p.RESULTAT,
    p.BEHANDLINGS_ID,
    p.KAFKA_TOPIC,
    p.KAFKA_OFFSET,
    p.KAFKA_PARTITION,
    pk_EF_FAGSAK as FK_EF_FAGSAK
  from pre_final p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_VILKÅR,
  FK_EF_FAGSAK,
  VILKAAR,
  RESULTAT,
  BEHANDLINGS_ID,
  KAFKA_TOPIC,
  KAFKA_OFFSET,
  KAFKA_PARTITION,
  localtimestamp AS LASTET_DATO
from final

