with stg_fam_ef_arena_fak_vedtak_fakta as (
  select * from {{source ('arena_stonad', 'fak_vedtak_fakta')}}
),

final as (
  select * from stg_fam_ef_arena_fak_vedtak_fakta
)

select * from final