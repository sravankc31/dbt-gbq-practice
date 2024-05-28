with source as (

    select * from {{ source('stripe','payment') }}

),

staged as (

    select
        id as payment_id,
        order_id as order_id,
        payment_method as payment_method,
        amount / 100 as amount, -- amount is stored in cents, convert it to dollars
        status , 
        current_date as inserted_at 
    from source

)

select * from staged