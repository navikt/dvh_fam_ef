with stg_fam_ef_arena_fak_stonad as (
  select * from {{ source ('arena_stonad','fak_stonad') }}
),

final as (
  select * from stg_fam_ef_arena_fak_stonad
)

select * from final