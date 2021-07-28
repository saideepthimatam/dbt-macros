{% macro device_mapping(type, category) %}

    case
        when {{ type }} = 'app' then 'App'
        when {{ type }} = 'web' and {{ category }} = 'mobile' then 'Mobile (Web)'
        when {{ type }} = 'web' and {{ category }} = 'tablet' then 'Tablet (Web)'
        when {{ type }} = 'web' and {{ category }} = 'desktop' then 'Desktop'
        else 'Other or Unknown'
    end

{% endmacro %}