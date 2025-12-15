with stg_fam_ef_arena_dim_person as (
  select * from {{ source ( 'arena_stonad', 'dim_person') }}
),

final as (
  select * from stg_fam_ef_arena_dim_person
)

select * from final