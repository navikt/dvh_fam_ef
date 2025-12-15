with stg_fam_ef_arena_fak_sak_vedtak as (
  select * from {{source ('arena_stonad', 'fak_arena_sak_vedtak')}}
),

final as (
  select * from stg_fam_ef_arena_fak_sak_vedtak
)

select * from final