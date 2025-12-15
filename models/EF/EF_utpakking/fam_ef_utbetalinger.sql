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
  json_table(melding, '$'
    COLUMNS (
      BEHANDLINGS_ID                  VARCHAR2 PATH '$.behandlingId'
      ,nested                path '$.utbetalinger[*]' columns (
         belop              varchar2 path '$.beløp'
        ,samordningsfradrag varchar2 path '$.samordningsfradrag'
        ,inntekt            varchar2 path '$.inntekt'
        ,inntektsreduksjon  varchar2 path '$.inntektsreduksjon'
        ,fra_og_med         varchar2 path '$.fraOgMed'
        ,til_og_med         varchar2 path '$.tilOgMed'
        ,person_ident       varchar2 path '$.utbetalingsdetalj.gjelderPerson.personIdent'
        ,klassekode         varchar2 path '$.utbetalingsdetalj.klassekode'
        ,delytelse_id       varchar2 path '$.utbetalingsdetalj.delytelseId'
        )
      )
    )j
    --where json_value (melding, '$.utbetalinger.size()' )> 0
),

pre_final as (
  select
    behandlings_id,
    belop,
    samordningsfradrag,
    person_ident,
    nvl(b.fk_person1, -1) fk_person1,
    inntekt,
    inntektsreduksjon,
    fra_og_med,
    til_og_med,
    klassekode,
    delytelse_id,
    kafka_offset,
    kafka_topic,
    kafka_partition
  from
    kolonner
  left outer join dt_person.ident_off_id_til_fk_person1 b on
    kolonner.person_ident=b.off_id
    and b.gyldig_fra_dato<=kolonner.kafka_mottatt_dato
    and b.gyldig_til_dato>=kolonner.kafka_mottatt_dato
    and b.skjermet_kode=0
),

final as (
  select
    p.behandlings_id,
    p.belop,
    p.person_ident,
    p.fk_person1,
    p.samordningsfradrag,
    p.inntekt,
    p.inntektsreduksjon,
    p.fra_og_med,
    p.til_og_med,
    p.klassekode,
    p.delytelse_id,
    p.kafka_offset,
    p.kafka_topic,
    p.kafka_partition,
    pk_EF_FAGSAK as FK_EF_FAGSAK
  from pre_final p
  join ef_fagsak b
  on p.kafka_offset = b.kafka_offset

)

select
  dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_UTBETALINGER,
  FK_EF_FAGSAK,
  BELOP,
  SAMORDNINGSFRADRAG,
  INNTEKT,
  INNTEKTSREDUKSJON,
  TO_DATE(FRA_OG_MED, 'YYYY-MM-DD') FRA_OG_MED,
  TO_DATE(TIL_OG_MED, 'YYYY-MM-DD') TIL_OG_MED,
  case when fk_person1 = -1 then person_ident
    else null
  end PERSON_IDENT,
  KLASSEKODE,
  DELYTELSE_ID,
  FK_PERSON1,
  BEHANDLINGS_ID,
  KAFKA_TOPIC,
  KAFKA_OFFSET,
  KAFKA_PARTITION,
  localtimestamp AS LASTET_DATO
From final

