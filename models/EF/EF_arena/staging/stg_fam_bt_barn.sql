with stg_fam_bt_barn as (
  select * from {{ source ('fam_bt', 'fam_bt_barn') }}
),

final as (
  select --* from stg_fam_bt_barn
  fk_person1,
  fkb_person1,
  fodsel_aar_barn,
  fodsel_mnd_barn,
  stat_aarmnd

  from stg_fam_bt_barn where stat_aarmnd = '{{ var ("periode") }}'
)

select * from final