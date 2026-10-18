# Hybrid AI integration contract (not yet connected)

Do not embed paid provider API keys in an APK, JavaScript asset or GDScript.
Use a user-owned HTTPS proxy or a backend that authenticates users and enforces quotas.

Recommended request: POST /v1/companion/chat
JSON: {"message":"Ahoj","session_id":"...","memory_summary":"...","mode":"romance"}
Response: {"reply":"Ahoj!","memory_summary":"..."}

Offline fallback should be a small on-device model with explicit performance and RAM constraints, or the existing local scripted responses while offline. Do not market scripted replies as a real language model.

Persist conversations with user consent, provide export/delete, and never treat the 18+ confirmation checkbox as robust age verification. Implement policy and age assurance appropriate to distribution channel before shipping mature content.
