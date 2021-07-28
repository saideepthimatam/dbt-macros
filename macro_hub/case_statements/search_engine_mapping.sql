{% macro search_engine_mapping(channel, ts_source) %}

    case lower({{ channel }})
        when 'organic search' then
            case
                when lower({{ ts_source }}) = 'google' or lower({{ ts_source }}) like '%google.com' then 'Google'
                when lower({{ ts_source }}) = 'bing' or lower({{ ts_source }}) like '%bing.com' then 'Bing'
                when lower({{ ts_source }}) = 'duckduckgo' or lower({{ ts_source }}) like '%duckduckgo.com' then 'DuckDuckGo'
                when lower({{ ts_source }}) = 'yahoo' or lower({{ ts_source }}) like '%yahoo.com' then 'Yahoo'
                else 'Other Search Engine'
            end
        else {{ channel }}
    end

{% endmacro %}

