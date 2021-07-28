{% macro hit_page_type_mapping(type, bucket) %}

    case
        when {{ type }} in ('Individual Question',
                                'Individual Review',
                                'Doctor Photos List',
                                'Homepage',
                                'Create a Question')
            then {{ type }}
        when {{ bucket }} = 'Provider Profile' then {{ bucket }}
        else 'Other Page Type'
    end

{% endmacro %}