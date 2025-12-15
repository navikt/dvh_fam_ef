with stg_fam_ef_arena_dim_kjonn as (
  select * from {{ source ('arena_stonad', 'dim_kjonn') }}
),

final as (
  select --* from stg_fam_ef_arena_dim_kjonn
  pk_dim_kjonn,
  kjonn_kode
  from stg_fam_ef_arena_dim_kjonn
)

select * from final