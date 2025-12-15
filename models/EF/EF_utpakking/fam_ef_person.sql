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

pre_final_barn_person as (
  select * from ef_meta_data
    ,json_table(melding, '$'
      columns (
        behandlings_id    varchar2 path '$.behandlingId'
        ,nested            path '$.barn[*]'
        columns (
        person_ident varchar2 path '$.personIdent'
        ,termindato        varchar2 path '$.termindato'
        )
      )
    ) j
    --where json_value (melding, '$.barn.size()' )> 0
),

pre_final as (
  select
    behandlings_id,
    person_ident,
    nvl(ident.fk_person1, -1) fk_person1,
    kafka_offset,
    kafka_topic,
    kafka_partition,
    termindato
  from pre_final_barn_person  p
  left outer join dt_person.ident_off_id_til_fk_person1 ident
  on p.person_ident = ident.off_id
  and p.kafka_mottatt_dato between ident.gyldig_fra_dato and ident.gyldig_til_dato
  and ident.skjermet_kode = 0
),

final as (
  select
    p.behandlings_id,
    case when p.fk_person1 = -1 then p.person_ident
          else null
    end person_ident,
    p.fk_person1,
    p.kafka_offset,
    p.kafka_topic,
    p.kafka_partition,
    p.termindato,
    b.pk_EF_FAGSAK as FK_EF_FAGSAK
  from pre_final p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset
)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_PERSON,
  FK_EF_FAGSAK,
  PERSON_IDENT,
  to_date(TERMINDATO,'yyyy-mm-dd') TERMINDATO,
  'BARN' RELASJON,
  FK_PERSON1,
  BEHANDLINGS_ID,
  KAFKA_TOPIC,
  KAFKA_OFFSET,
  KAFKA_PARTITION,
  localtimestamp AS LASTET_DATO
from final






