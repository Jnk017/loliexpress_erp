# Décisions de validation

- Production n’est accessible qu’en lecture seule. Toute modification passe par Gate ou une cible isolée explicitement autorisée.
- Le code de référence est synchronisé sur la branche de gate. Les preuves historiques restent liées à leur SHA.
- L’exclusion de GitHub Actions demeure. Les vérifications du workflow sont locales ou sur les outils de build autorisés.
- Le test de base vierge se déroule avant provisionnement. Les comptes de Gate sont conservés.
- Les réglages métier et comptables nécessitant un arbitrage sont documentés avec leur dépendance. Les tests utilisent exclusivement des données contrôlées hors production.
