with stg_fam_ef_arena_dim_omraade as(
  select * from {{source ('arena_stonad', 'dim_f_stonad_omraade')}}
),

final as (
  --select * from stg_fam_ef_arena_dim_omraade
  select pk_dim_f_stonad_omraade, stonad_kode, stonad_navn
  from stg_fam_ef_arena_dim_omraade
  where stonad_kode in ('TSOBOUTG','TSODAGREIS','TSOFLYTT','TSOLMIDLER','TSOREISAKT',
  'TSOREISARB','TSOREISOBL','TSOTILBARN','TSOTILFAM')
)

select * from final


