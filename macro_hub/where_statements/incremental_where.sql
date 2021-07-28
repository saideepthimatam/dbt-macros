{% macro incremental_where(source_table, date_col) %}

    {% if source_table == 'stage' %}

        {% if var('manual_run') == true %}
            {{date_col}} {{ date_between(var('manual_start'), var('manual_end'), true) }}
        {% elif is_incremental() %}
            {{date_col}} >= {{ days_ago(var('incremental_run')) }}
        {% elif target.name != 'prod' %}
            {{date_col}} {{ date_between(days_ago(7), today()) }}
        {% else %}
            {{date_col}} {{ date_between(days_ago(30), today()) }}
        {% endif %}

    {% elif source_table == 'raw' %}

        {% if var('manual_run') == true %}
            {{ shard_between(var('manual_start'), var('manual_end'), true) }}
        {% elif is_incremental() %}
            {{ shard_between(days_ago(var('incremental_run')-1,format='string'), today(format='string')) }}
        {% elif target.name != 'prod' %}
            {{ shard_between(days_ago(7,format='string'), today(format='string')) }}
        {% else %}
            {{ shard_between(days_ago(30,format='string'), today(format='string')) }}
        {% endif %}

    {% endif %}

{% endmacro %}


{% macro date_between(start_date,end_date,quoted=false) -%}

    between {% if quoted -%} date('{{ start_date[:4] }}-{{ start_date[-4:6] }}-{{ start_date[-2:] }}') {%- else -%} date({{ start_date }}) {%- endif %}
      and {% if quoted -%} date('{{ end_date[:4] }}-{{ end_date[-4:6] }}-{{ end_date[-2:] }}') {%- else -%} date({{ end_date }}) {%- endif %}

{%- endmacro %}