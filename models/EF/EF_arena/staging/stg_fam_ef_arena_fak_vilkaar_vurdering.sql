with stg_fam_ef_arena_fak_vilkaar_vurdering as (
  select * from {{source ('arena_stonad', 'fak_vilkaar_vurdering')}}
),

final as (
  select * from stg_fam_ef_arena_fak_vilkaar_vurdering
)

select * from final