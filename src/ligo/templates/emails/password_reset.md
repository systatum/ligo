{% translate "emails.password_reset.intro" %}

{% translate "emails.password_reset.instructions" %}

<a href="{{ base_url }}/auth/reset-password/confirm/{{ hashed_id }}/{{ token }}" style="display:inline-block;background:#569aec;color:white;font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:14px;font-weight:500;line-height:120%;margin:0;text-decoration:none;text-transform:none;padding:10px 25px;border-radius:2px;">
{% translate "emails.password_reset.cta" %}
</a>

{% translate "emails.password_reset.or_visit" %}

<{{ base_url }}/auth/reset-password/confirm/{{ hashed_id }}/{{ token }}>

{% translate "emails.password_reset.notice" %}
