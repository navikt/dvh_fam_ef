with stg_fam_ef_arena_dim_person_k_info as (
  select * from {{ source ('dt_person', 'dim_person_kontaktinfo') }}
),

final as (
  select --* from stg_fam_ef_arena_dim_person_k_info

  fk_person1,
  fodselsnummer_gjeldende
  from stg_fam_ef_arena_dim_person_k_info
)

select * from final