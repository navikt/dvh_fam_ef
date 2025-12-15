with stg_fam_ef_arena_dim_vilkaar_type as (
  select * from {{source ('arena_stonad', 'dim_vilkaar_type')}}
),

final as (
  select * from stg_fam_ef_arena_dim_vilkaar_type
)

select * from final