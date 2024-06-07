----testing git branch merging

{{
    config(
        materialized='table'
    )
}}
with source as (

    select * from {{ source('jaffle_shop','customers') }}

),
----testing git branch

staged as (

    select  
        id as customer_id,
        first_name, 
        last_name
    from source

)

select * , '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' as _audit_run_id from staged
