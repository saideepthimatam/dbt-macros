{# reference:
https://github.com/fishtown-analytics/dbt/blob/0.11.1/dbt/include/global_project/macros/materializations/incremental/bigquery_incremental.sql
https://github.com/fishtown-analytics/dbt/blob/0.11.1/dbt/include/global_project/macros/materializations/common/merge.sql
#}

{% materialization incremental_merge -%}

  {%- set unique_key = config.get('unique_key') -%}
  {%- set sql_where = config.get('sql_where') -%}
  {%- set dest_where = config.get('dest_where') -%}
  {%- if not dest_where -%}
    {%- set dest_where = hue.incremental_dest_where(config.get('partition_by')['field'], config.get('merge_partition_range')) -%}
  {%- endif -%}
  
  {%- set replace_partitions = config.get('replace_partitions',False) -%}

  {%- set non_destructive_mode = (flags.NON_DESTRUCTIVE == True) -%}
  {%- set full_refresh_mode = (flags.FULL_REFRESH == True) -%}

  {% if not dest_where %}
    {{ exceptions.raise_compiler_error("Must supply a dest_where clause") }}
  {% endif %}

  {% if non_destructive_mode %}
    {{ exceptions.raise_compiler_error("--non-destructive mode is not supported on BigQuery") }}
  {% endif %}

  {%- set identifier = model['alias'] -%}

  {%- set old_relation = adapter.get_relation(database=target.project, schema=schema, identifier=identifier) -%}

  {%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, type='table') -%}

  {%- set exists_as_table = (old_relation is not none and old_relation.is_table) -%}
  {%- set exists_not_as_table = (old_relation is not none and not old_relation.is_table) -%}

  {%- set should_drop = (full_refresh_mode or exists_not_as_table) -%}
  {%- set force_create = (full_refresh_mode) -%}

  -- setup
  {% if old_relation is none -%}
    -- noop
  {%- elif should_drop -%}
    {{ adapter.drop_relation(old_relation) }}
    {%- set old_relation = none -%}
  {%- endif %}

  {% set source_sql -%}
     {#-- wrap sql in parens to make it a subquery --#}
     (
        select * from (
            {{ sql }}
        )
        {# /*where ({{ sql_where }}) or ({{ sql_where }}) is null*/ #} --deprecating for dbt v0.13.0
    )
  {%- endset -%}


  {{ run_hooks(pre_hooks) }}

  -- build model
  {% if force_create or old_relation is none -%}
    {%- call statement('main') -%}
      {{ create_table_as(False, target_relation, sql) }}
    {%- endcall -%}
  {%- else -%}
     {% set dest_columns = adapter.get_columns_in_relation(this) %}
     {%- call statement('main') -%}
       {% if replace_partitions %}
         {{ get_replace_sql(target_relation, source_sql, dest_columns, dest_where) }}
       {% else %}
         {{ get_merge_sql(target_relation, source_sql, unique_key, dest_columns, dest_where) }}
       {% endif %}
     {% endcall %}
  {%- endif %}

  {{ run_hooks(post_hooks) }}

  -- Return the relations created in this materialization
  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}

{% macro get_merge_sql(target, source, unique_key, dest_columns, dest_where) -%}
    {%- set dest_cols_csv = dest_columns | map(attribute="name") | join(', ') -%}

    merge into {{ target }} as DBT_INTERNAL_DEST
    using {{ source }} as DBT_INTERNAL_SOURCE

    {% if unique_key %}
        on DBT_INTERNAL_SOURCE.{{ unique_key }} = DBT_INTERNAL_DEST.{{ unique_key }}
    {% else %}
        on FALSE
    {% endif %}
        and {{dest_where}}

    {% if unique_key %}
    when matched then update set
        {% for column in dest_columns -%}
            {{ column.name }} = DBT_INTERNAL_SOURCE.{{ column.name }}
            {%- if not loop.last %}, {%- endif %}
        {%- endfor %}
    {% endif %}

    when not matched then insert
        ({{ dest_cols_csv }})
    values
        ({{ dest_cols_csv }})

{% endmacro %}

{% macro get_replace_sql(target, source, dest_columns, dest_where) -%}
    {%- set dest_cols_csv = dest_columns | map(attribute="name") | join(', ') -%}

    {{ log("Replacing partitions in " ~ target ~ " where " ~ dest_where, info = true) }}

    merge into {{ target }} as DBT_INTERNAL_DEST
    using {{ source }} as DBT_INTERNAL_SOURCE

    on FALSE

    when not matched by source and {{dest_where}}
        then delete

    when not matched by target then insert
        ({{ dest_cols_csv }})
    values
        ({{ dest_cols_csv }})

{% endmacro %}

{% macro incremental_dest_where(partition_by, merge_partition_range=none) %}
		{% if merge_partition_range is none %}
		{% set merge_partition_range = var('incremental_run') | int %}
		{% endif %}

    {% if 'date(' in partition_by %}
        {% set colname = partition_by|replace('date(','')|replace(')','') %}
        {% set date_col = 'date(dbt_internal_dest.'~colname~')' %}
    {% else -%}
        {% set date_col = 'dbt_internal_dest.'~partition_by %}
    {% endif %}
    
    {%- set dest_where -%}

    {%- if var('manual_run') == true -%}
        {{date_col}} {{ date_between(var('manual_start'), var('manual_end'), true) }}
    {%- else -%}
        {{date_col}} >= {{ days_ago(merge_partition_range | int) }}
    {%- endif -%}
    
    {%- endset -%}
    
    {{ return(dest_where) }}
    
{% endmacro %}
