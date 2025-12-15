with stg_fam_ef_arena_person_ikke_skjermet as (
  select * from {{ source ( 'dt_person', 'dvh_person_ident_off_id_ikke_skjermet') }}
),

final as (
  select * from stg_fam_ef_arena_person_ikke_skjermet
)

select * from final