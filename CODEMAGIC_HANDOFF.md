# Remise Codemagic — LoliExpress ERP

> **Current status — 2026-11-25:** Flutter 3.35.7; verify the exact SHA and ensure MOBILE_SUPABASE_URL is the isolated Gate URL before build. Appcircle is an alternative. No APK on the audited SHA has been verified; retain artifact hash and logs. No production key in builds. [Current audit](docs/gate_audit_2026-11-25.md).


## Checklist opérateur

- [ ] Connecter `Jnk017/loliexpress_erp` dans Codemagic et créer ou sélectionner son application.
- [ ] Sélectionner `gate/final-verification` et le workflow `build-android-apk`.
- [ ] Confirmer dans GitHub, **Settings → Webhooks**, que l’intégration Codemagic reçoit les événements push.
- [ ] Configurer le groupe `loliexpress-gate-local` dans l’interface Codemagic, avec `MOBILE_SUPABASE_URL` pointant vers le projet cloud dédié et `SUPABASE_ANON_KEY` contenant sa clé publique. Utiliser la clé publique/anon, jamais la clé de service.
- [ ] Si une notification est souhaitée, renseigner le destinataire dans l’intégration e-mail via le mécanisme pris en charge par Codemagic. `CODEMAGIC_NOTIFY_EMAIL` peut contenir cette adresse côté opérateur. Le YAML actuel publie sur l’onglet **Artifacts** sans notification e-mail.
- [ ] Vérifier que le build correspond au SHA complet du push puis télécharger `app-debug.apk` dans `~/mobile_artifacts/`.

Le webhook, les variables et le build restent à confirmer par l’opérateur. Codemagic compile l’APK. Les tests se font localement et sur le téléphone.

## Déclenchement depuis Android

Après configuration du webhook et des variables, prévenir Codex. Codex effectue le push de déclenchement sur la branche du gate. Depuis [Codemagic](https://codemagic.io/), suivre le build et télécharger l’APK dans **Artifacts**, ou via la notification si l’intégration e-mail est configurée. Le délai dépend de la file de compilation.

Suivre ensuite le [guide Android](MOBILE_HANDOFF.md).
