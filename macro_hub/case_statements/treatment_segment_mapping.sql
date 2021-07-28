{% macro treatment_segment_mapping(topic, segment, nudity, btb) %}

    case
        when {{ topic }} is null then 'No Topic on Page'
        when {{ segment }} in ('Minimally Invasive Aesthetics','Dentistry') then {{ segment }}
        when {{ segment }} = 'Plastic Surgery' and ({{ nudity }} or {{ btb }}) then 'Plastic Surgery (NSFW)'
        when {{ segment }} = 'Plastic Surgery' and not({{ nudity }} or {{ btb }}) then 'Plastic Surgery (SFW)'
        else 'Other Treatments'
    end

{% endmacro %}