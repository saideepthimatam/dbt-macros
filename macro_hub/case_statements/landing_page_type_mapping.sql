{% macro landing_page_type_mapping(type, bucket) %}

    case
        when {{ type }} in ('Individual Review',
                    'Individual Question',
                    'Questions List',
                    'Homepage',
                    'Reviews List',
                    'Procedure Overview',
                    'Blog Post',
                    'Cost Page')
            then {{ type }}
        when {{ bucket }} = 'Provider Profile' then {{ bucket }}
        when {{ bucket }} in ('Find a Provider','Find a Provider Results') then 'Find a Provider'
        else 'Other Page Type'
    end

{% endmacro %}


