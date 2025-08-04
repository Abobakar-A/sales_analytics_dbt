{% macro dynamic_partition(column, interval) %}

    {# 
        هذا الماكرو يقوم بتقسيم البيانات إلى مجموعتين: 'recent' و 'historical'.
        'recent': هي البيانات التي تقع ضمن فترة زمنية محددة من التاريخ الحالي.
        'historical': هي جميع البيانات الأخرى.
        
        - column: هو اسم عمود التاريخ الذي تريد استخدامه للتقسيم.
        - interval: هو نوع الفاصل الزمني (مثال: 'day', 'month', 'year').
    #}

    CASE
        {# التحقق مما إذا كان تاريخ العمود يقع ضمن الفاصل الزمني المحدد #}
        WHEN date({{ column }}) >= date_sub(current_date(), interval 3 {{ interval }}) 
        THEN 'recent'

        {# إذا لم يكن ضمن الفاصل الزمني، فإنه يعتبر تاريخيًا #}
        ELSE 'historical'
    END AS partition_group

{% endmacro %}
     
