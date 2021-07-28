{% macro geo_mapping(country) %}

    case
        when {{ country }} in ('United States','United Kingdom','Canada','Australia','India') then {{ country }}
        when ifnull({{ country }},'(not set)') = '(not set)' then 'Unknown'
        else 'Other International'
    end

{% endmacro %}