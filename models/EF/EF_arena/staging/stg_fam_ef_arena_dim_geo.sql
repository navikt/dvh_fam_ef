with stg_fam_ef_arena_dim_geo as (
  select * from {{ source ('arena_stonad', 'dim_geografi') }}
),

final as (
  select --* from stg_fam_ef_arena_dim_geo
  pk_dim_geografi,
  KOMMUNE_NR,
	BYDEL_NR
  from stg_fam_ef_arena_dim_geo

)

select * from final