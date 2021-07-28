{% macro signup_method_mapping(category, label, act) %}

    case
        when ( {{ category }} = 'registrations' and {{ act }} in ('sign up', 'google signup success') ) then
            case
                when {{ label }} like 'google%' or {{ act }} = 'Successful Google Signup' then 'Google'
                when {{ label }} like 'apple%' or {{ act }} = 'Successful Apple Signup' then 'Apple'
                when {{ label }} like 'facebook%' or {{ act }} = 'Successful Facebook Signup' then 'Facebook'
                else 'Email'
            end
        when ( {{ category }} = 'User Signup' and {{ act }} like 'Successful%Signup') then
            case
                when {{ label }} like 'google%' or {{ act }} = 'Successful Google Signup' then 'Google'
                when {{ label }} like 'apple%' or {{ act }} = 'Successful Apple Signup' then 'Apple'
                when {{ label }} like 'facebook%' or {{ act }} = 'Successful Facebook Signup' then 'Facebook'
                else 'Email'
            end
        else null
    end
{% endmacro %}