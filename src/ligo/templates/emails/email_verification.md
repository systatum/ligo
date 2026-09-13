{% translate "emails.email_verification.intro" %}

{% translate "emails.email_verification.instructions" %}

<a href="{{ verification_url }}" style="display:inline-block;background:#569aec;color:white;font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:14px;font-weight:500;line-height:120%;margin:0;text-decoration:none;text-transform:none;padding:10px 25px;border-radius:2px;">
{% translate "emails.email_verification.cta" %}
</a>

{% translate "emails.email_verification.code_intro" %}

**{{ verification_code }}**

{% translate "emails.email_verification.alternative_link" %}

<a href="{{ form_url }}">{{ form_url }}</a>

{% translate "emails.email_verification.notice" %}
