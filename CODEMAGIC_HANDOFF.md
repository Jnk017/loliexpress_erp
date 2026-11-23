# Remise Codemagic — LoliExpress ERP

## Checklist opérateur

- [ ] Connecter `Jnk017/loliexpress_erp` dans Codemagic et créer ou sélectionner son application.
- [ ] Sélectionner `gate/final-verification` et le workflow `build-android-apk`.
- [ ] Confirmer dans GitHub, **Settings → Webhooks**, que l’intégration Codemagic reçoit les événements push.
- [ ] Configurer le groupe `loliexpress-gate-local` dans l’interface Codemagic, avec `MOBILE_SUPABASE_URL` vérifiée sur le téléphone et `SUPABASE_ANON_KEY` issue de la pile de test isolée. Utiliser la clé publique/anon, jamais la clé de service.
- [ ] Si une notification est souhaitée, renseigner le destinataire dans l’intégration e-mail via le mécanisme pris en charge par Codemagic. `CODEMAGIC_NOTIFY_EMAIL` peut contenir cette adresse côté opérateur. Le YAML actuel publie sur l’onglet **Artifacts** sans notification e-mail.
- [ ] Vérifier que le build correspond au SHA complet du push puis télécharger `app-debug.apk` dans `~/mobile_artifacts/`.

Le webhook, les variables et le build restent à confirmer par l’opérateur. Codemagic compile l’APK. Les tests se font localement et sur le téléphone.

## Push de déclenchement par l’opérateur

À exécuter après validation de l’URL et du webhook.

```bash
set -e
test "$(git branch --show-current)" = gate/final-verification
test -z "$(git status --porcelain)"
git check-ignore .env.test
printf 'gate: trigger codemagic build\n\n\nskip-checks: true\n' |
  git commit --allow-empty --cleanup=verbatim -F -
git push origin HEAD:refs/heads/gate/final-verification
```

Récupérer l’APK depuis la page du build, consigner son SHA-256 et suivre le [guide Android](MOBILE_HANDOFF.md).
