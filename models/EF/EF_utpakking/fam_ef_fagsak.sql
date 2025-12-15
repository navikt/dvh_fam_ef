{{
    config(
        materialized='incremental'
    )
}}

with ef_meta_data as (
  select * from {{ref ('ef_meldinger_til_aa_pakke_ut')}}
),

pre_final as (
select * from ef_meta_data,
  json_table(melding, '$'
    COLUMNS (
        fagsak_id                        VARCHAR2 PATH '$.fagsakId'
        ,BEHANDLINGS_ID                  VARCHAR2 PATH '$.behandlingId'
        ,relatert_behandlings_id         VARCHAR2 PATH '$.relatertBehandlingId'
        ,adressebeskyttelse              VARCHAR2 PATH '$.adressebeskyttelse'
        ,behandling_type                 VARCHAR2 PATH '$.behandlingType'
        ,behandlings_aarsak              VARCHAR2 PATH '$.behandlingÅrsak'
        ,vedtaks_status                  VARCHAR2 PATH '$.vedtak'
        ,stonadstype                     VARCHAR2 PATH '$.stønadstype'
        ,person_ident                    VARCHAR2 PATH '$.person.personIdent'
        ,aktivitetsplikt_inntreffer_dato VARCHAR2 PATH '$.aktivitetskrav.aktivitetspliktInntrefferDato'
        ,har_sagt_opp_arbeidsforhold     VARCHAR2 PATH '$.aktivitetskrav.harSagtOppArbeidsforhold'
        ,funksjonell_id                  VARCHAR2 PATH '$.funksjonellId'
        ,vedtaks_tidspunkt               VARCHAR2 PATH '$.tidspunktVedtak'
        ,aktivitetsvilkaar_barnetilsyn   VARCHAR2 PATH '$.aktivitetskrav'
        ,krav_mottatt                    VARCHAR2 PATH '$.kravMottatt'
        ,årsak_revurderings_kilde        VARCHAR2 PATH '$.årsakRevurdering.opplysningskilde'
        ,revurderings_årsak              VARCHAR2 PATH '$.årsakRevurdering.årsak'
        ,medlem_Mer_Enn_5_Aar_Eos        VARCHAR2 PATH '$.eøsUnntak.medlemMerEnn5ÅrEøs'
        ,medlem_Mer_Enn_5_Aar_Eos_Annen_Forelder_Trygdedekket_I_Norge VARCHAR2 PATH '$.eøsUnntak.medlemMerEnn5ÅrEøsAnnenForelderTrygdedekketINorge'
        ,oppholder_Seg_I_Annet_Eos_Land  VARCHAR2 PATH '$.eøsUnntak.oppholderSegIAnnetEøsLand'
         )
        ) j
),

final as (
  select
     p.fagsak_id
    ,p.behandlings_id
    ,p.relatert_behandlings_id
    ,p.adressebeskyttelse
    ,p.behandling_type
    ,p.medlem_Mer_Enn_5_Aar_Eos
    ,p.medlem_Mer_Enn_5_Aar_Eos_Annen_Forelder_Trygdedekket_I_Norge
    ,p.oppholder_Seg_I_Annet_Eos_Land
    ,p.behandlings_aarsak
    ,p.vedtaks_status
    ,p.stonadstype
    ,p.person_ident
    ,to_date(p.krav_mottatt,'yyyy-mm-dd') krav_mottatt
    ,p.årsak_revurderings_kilde
    ,p.revurderings_årsak
    ,p.aktivitetsvilkaar_barnetilsyn
    ,nvl(ident.fk_person1, -1) as fk_person1
    ,to_date(p.aktivitetsplikt_inntreffer_dato,'yyyy-mm-dd') aktivitetsplikt_inntreffer_dato
    ,CASE
      WHEN p.har_sagt_opp_arbeidsforhold = 'false' THEN 0
      WHEN p.har_sagt_opp_arbeidsforhold = 'true' THEN 1
      END har_sagt_opp_arbeidsforhold
    ,p.funksjonell_id
    ,CASE
      WHEN LENGTH(p.VEDTAKS_TIDSPUNKT) = 25 THEN CAST(to_timestamp_tz(p.VEDTAKS_TIDSPUNKT, 'yyyy-mm-dd"T"hh24:mi:ss TZH:TZM') AT TIME ZONE 'Europe/Belgrade' AS TIMESTAMP)
      ELSE CAST(to_timestamp_tz(p.VEDTAKS_TIDSPUNKT, 'FXYYYY-MM-DD"T"HH24:MI:SS.FXFFTZH:TZM') AT TIME ZONE 'Europe/Belgrade' AS TIMESTAMP)
      END VEDTAKS_TIDSPUNKT
    ,p.pk_ef_meta_data as fk_ef_meta_data
    ,p.kafka_offset
    ,p.KAFKA_TOPIC
    ,p.KAFKA_PARTITION
  from pre_final p
  left outer join dt_person.ident_off_id_til_fk_person1 ident
  on p.person_ident = ident.off_id
  and p.kafka_mottatt_dato between ident.gyldig_fra_dato and ident.gyldig_til_dato
  and ident.skjermet_kode = 0
)

select dvh_famef_kafka.hibernate_sequence.nextval as PK_EF_FAGSAK
  ,FK_EF_META_DATA
  ,FK_PERSON1
  ,AKTIVITETSPLIKT_INNTREFFER_DATO
  ,VEDTAKS_TIDSPUNKT
  ,KAFKA_TOPIC
  ,KAFKA_OFFSET
  ,KAFKA_PARTITION
  ,localtimestamp AS lastet_dato
  ,cast(null as varchar2(20)) FAGSAK_ID_GML
  ,cast(null as varchar2(20)) BEHANDLINGS_ID_GML
  ,KRAV_MOTTATT
  ,FAGSAK_ID
  ,BEHANDLINGS_ID
  ,RELATERT_BEHANDLINGS_ID
  ,ADRESSEBESKYTTELSE
  ,BEHANDLING_TYPE
  ,BEHANDLINGS_AARSAK
  ,VEDTAKS_STATUS
  ,STONADSTYPE
  ,case when FK_PERSON1 = -1 then PERSON_IDENT
      else cast(null as varchar2(11))
  end PERSON_IDENT
  ,HAR_SAGT_OPP_ARBEIDSFORHOLD
  ,FUNKSJONELL_ID
  ,AKTIVITETSVILKAAR_BARNETILSYN
  ,cast(null as varchar2(20)) VEDTAKSBEGRUNNELSE_SKOLE
  ,ÅRSAK_REVURDERINGS_KILDE
  ,REVURDERINGS_ÅRSAK
  ,case when medlem_Mer_Enn_5_Aar_Eos = 'true' then 1
  else 0
  end medlem_Mer_Enn_5_Aar_Eos
  ,case when oppholder_Seg_I_Annet_Eos_Land = 'true' then 1
  else 0
  end oppholder_Seg_I_Annet_Eos_Land
  ,case when medlem_Mer_Enn_5_Aar_Eos_Annen_Forelder_Trygdedekket_I_Norge = 'true' then 1
  else 0
  end medlem_Mer_Enn_5_Aar_Eos_Annen_Forelder_Trygdedekket_I_Norge
from final