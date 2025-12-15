with stg_fam_ef_arena_dim_vedtak_postering as (
  select * from {{ source ( 'arena_stonad', 'dim_vedtak_postering') }}
),

final as (
  select * from stg_fam_ef_arena_dim_vedtak_postering
)

select * from final