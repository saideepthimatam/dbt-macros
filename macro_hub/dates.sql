{% macro days_ago(n,format='date',quoted=true) -%}
{#
  -macro that produces date which is current date (in UTC) minus 'n' days
  -n: specifies the number of "days ago"
  -format: specifies the format in which the date value is returned
  -quoted: specifies if the date value retured should be quoted as a string
#}
    {%- set is_pst = config.get('pst') -%}

    {% if is_pst == True %}
      {{ days_ago_pst(n, format, quoted) }}
    {%- else -%}
      {%- set today = modules.datetime.date.today() -%}
      {%- set interval = modules.datetime.timedelta(days=n) -%}
      {%- set past_date = (today - interval) -%}
      {%- set result = past_date.strftime(datestring(format)) -%}
      {%- if quoted -%}'{{ result }}'{%- else -%}{{ result }}{%- endif -%}
    {%- endif -%}

{%- endmacro %}


{% macro today(format='date',quoted=true) -%}
    {%- set result = modules.datetime.date.today().strftime(datestring(format)) -%}
    {%- if quoted -%}'{{ result }}'{%- else -%}{{ result }}{%- endif -%}
{%- endmacro %}


{% macro shard_between(start_date,end_date,quoted=false) -%}

    ((
        _table_suffix between {% if quoted -%} '{{ start_date }}' {%- else -%} {{ start_date }} {%- endif %}
      and {% if quoted -%} '{{ end_date }}' {%- else -%} {{ end_date }} {%- endif %}

        and _table_suffix not like 'intraday%'

    )

    {% if end_date == today(format='string') %}
        or _table_suffix = '{{ "intraday_" ~ today(format="string",quoted=false) }}'
    {% endif %}

    )

{%- endmacro %}


{% macro datestring(format) %}

    {% if format == 'string' %}
        {{ return("%Y%m%d") }}
    {% elif format == 'date' %}
        {{ return("%Y-%m-%d") }}
    {% endif %}

{% endmacro %}