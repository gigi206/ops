# ops vs Superpowers v5.0.2 — Ce que ops fait mieux

## 1. Critic adversarial (7 phases vs 1 reviewer basique)

**Superpowers** : `plan-document-reviewer` — une relecture simple du plan avec checklist.

**ops** : `critic.md` — 7 phases structurées :
1. Pre-engagement : prédire 3 problemes AVANT de lire le plan (anti-confirmation bias)
2. Review 4 lenses : missing steps, contradictions, security, CLAUDE.md compliance
3. Multi-perspective : Executor / Stakeholder / Skeptic simultanément
4. Gap analysis : "qu'est-ce qui MANQUE que personne n'a demandé ?"
5. Self-audit : LOW confidence → Open Questions (pas de faux positifs)
6. Realist check : pressure-test CRITICAL/MAJOR, downgrade si mitigé
7. Adversarial escalation : 1 CRITICAL ou 3+ IMPORTANT → mode "guilty until proven innocent"

## 2. Discovery handling (3 niveaux, 2 skills)

**Superpowers** : `DONE_WITH_CONCERNS` noté mais pas catégorisé. Pas de protocole d'arrêt.

**ops** : 3 niveaux dans `/ops:implement` ET `/ops:debug` :
- **Minor** : noter, continuer
- **Significant** : PAUSE obligatoire, présenter 2-3 options à l'utilisateur
- **Major** : STOP obligatoire, présenter options incluant `/ops:plan`

L'implementer NE PEUT PAS contourner silencieusement une découverte significative ou majeure.

## 3. Circuit breaker enrichi

**Superpowers** : après 3 échecs → "question the architecture". Stoppe et rapporte.

**ops** : après 3 échecs consécutifs :
1. Dispatch `researcher-code` (Opus) + `git-historian` (Sonnet) en parallèle pour diagnostic
2. Présente l'analyse de root cause à l'utilisateur
3. Propose 5 options concrètes (fix ciblé, alternative, `/ops:debug`, `/ops:plan`, abandon)
4. Attend la décision utilisateur

Même pattern enrichi dans le circuit breaker de `/ops:debug` (5+ fix attempts).

## 4. Security reviewer dédié + pipeline d'escalade

**Superpowers** : la sécurité est une ligne dans le code review ("no hardcoded secrets"). Pas d'agent dédié.

**ops** : pipeline à 2 étages :
1. `code-reviewer` fait un scan basique (secrets, injection, TLS, auth, input, PII)
2. Si Critical trouvé OU si la tâche touche auth/APIs/secrets/TLS/input/RBAC → dispatch `security-reviewer` (agent dédié)
3. Le `security-reviewer` fait une analyse profonde : threat analysis par catégorie, scénarios d'attaque concrets (qui/comment/impact), evidence-based
4. Après fix d'un Critical security → re-dispatch pour vérifier le fix
5. Le final review dispatche aussi le security-reviewer si l'implémentation a touché des zones sensibles

## 5. Git intelligence

**Superpowers** : aucun agent git. Pas d'analyse d'historique.

**ops** : `git-historian` avec 2 modes :
- **Research mode** (pendant `/ops:plan`) : timeline 6 mois, régressions, ownership, hotspots, milestones architecturaux. Output YAML structuré avec risk assessment HIGH/MEDIUM/LOW.
- **Investigation mode** (pendant `/ops:debug` et circuit breaker `/ops:implement`) : 30 jours, suspect commits, blame analysis, changes récents.

Intégré dans les 3 skills workflow (plan, implement, debug).

## 6. Détection LSP 4 niveaux

**Superpowers** : aucune détection LSP.

**ops** : pendant le planning (Step 2b), pour chaque langage détecté :
1. **Test** : `LSP documentSymbol` sur un fichier représentatif
2. **Marketplaces** : vérifier `claude-plugins-official` et `claude-code-lsps` dans settings
3. **Plugins** : vérifier l'installation et l'activation du plugin LSP
4. **Binaires** : vérifier que le language server est installé sur le système

Guide l'utilisateur à chaque niveau avec les commandes d'installation exactes.

## 7. LSP diagnostics dans le code review

**Superpowers** : pas de LSP dans le review process.

**ops** : `code-reviewer` Step 2 — run `LSP diagnostics` sur chaque fichier modifié. Type errors, missing imports, unresolved references → Critical findings automatiques. Skip si LSP non disponible.

## 8. Debug workflow (8 étapes vs 4 phases)

**Superpowers** : 4 phases (Observe → Hypothesize → Test → Fix). Bon mais basique.

**ops** : 8 étapes :
1. **Investigate** — error + reproduce + git-historian + data flow tracing
2. **Instrument** — ajouter du logging aux boundaries de composants AVANT d'hypothétiser
3. **Hypothesize** — max 3, avec evidence et critère de réfutation
4. **Test hypotheses** — incluant protocole non-déterministe (race conditions)
5. **Fix** — minimal, root cause only
6. **Code review** — code-reviewer + security escalation si nécessaire
7. **Discovery check** — 3 niveaux (minor/significant/major)
8. **Verify** — evidence avant claim

Plus : circuit breaker enrichi (5+ échecs → diagnostic + options).

## 9. Protocole bugs non-déterministes

**Superpowers** : rien de spécifique pour les race conditions ou bugs intermittents.

**ops** : dans Step 3 (Test Hypotheses) :
- Un seul run n'est PAS suffisant pour confirmer/réfuter
- Run au minimum 5 fois, enregistrer le taux succès/échec
- Ajouter instrumentation de timing pour identifier la fenêtre de race
- Chercher l'état partagé (accès concurrent sans synchronisation)
- Documenter les conditions de reproduction si uniquement sous charge

## 10. CLAUDE.md-driven tasks

**Superpowers** : CLAUDE.md est respecté comme convention. Pas de génération automatique de tâches.

**ops** : les règles CLAUDE.md sont des **task generators**. Chaque règle "when doing X, also do Y" génère une tâche explicite dans le plan avec description, fichiers, et commande de validation. Le critic vérifie que toutes les règles applicables ont une tâche correspondante.

## 11. Conformity check explicite

**Superpowers** : implicite dans le code review.

**ops** : étape dédiée (Step 2c) entre validation et code review :
- Le changement correspond au plan
- Pas de drift (changements non demandés)
- Pas d'anti-patterns de sécurité
- Conventions existantes préservées

## 12. Research adequacy quantitative

**Superpowers** : gate explicite mais basée sur "do we understand?" (Yes/No subjectif).

**ops** : critères mesurables avec preuves requises :

| Dimension         | Suffisant quand                             | Evidence requise                |
|-------------------|---------------------------------------------|---------------------------------|
| Technical context | Au moins 1 implémentation similaire trouvée | Citer `file:line`               |
| Dependencies      | Liste explicite des fichiers affectés       | Liste de researcher-code        |
| Risks             | Au moins 1 risque concret identifié         | Citer ce qui a été vérifié      |
| Documentation     | Sources consultées nommées avec versions    | e.g., "Context7: express v4.18" |

## 13. Clarity gate

**Superpowers** : explore le projet puis pose des questions.

**ops** : AVANT d'explorer, vérifie la compréhension de l'intent :
1. **What** — reformuler en une phrase
2. **Why** — quel problème ça résout
3. **Success** — comment l'utilisateur saura que ça marche

Si les 3 ne sont pas clairs → demander clarification AVANT d'explorer. Un check de 10 secondes qui évite des heures de planning sur la mauvaise chose.

## 14. Instruction priority documentée

**Superpowers** : mentionne la hiérarchie (User > Skills > System) dans `using-superpowers`.

**ops** : documenté dans chaque skill avec CLAUDE.md comme niveau intermédiaire :
1. User's explicit instructions
2. CLAUDE.md project rules
3. ops skill instructions
4. Default system prompt

Résout explicitement le conflit "que faire si CLAUDE.md dit 'pas de TDD' mais le skill dit 'toujours TDD'" → suivre CLAUDE.md.

## 15. Learnings capture structuré

**Superpowers** : pas de capture de learnings post-implémentation.

**ops** : template structuré dans Step 5 de `/ops:implement` :
- **Problems solved** — ce qui a cassé et comment c'était fixé
- **Decisions made** — choix non-évidents avec rationale
- **Gotchas discovered** — ce que les futurs agents doivent savoir
- **Patterns that worked** — approches réutilisables

## 16. Rule proposals (learnings → rules persistantes)

**Superpowers** : pas de mécanisme pour transformer les learnings en règles.

**ops** : Step 6 de `/ops:ship` — évalue chaque learning :
- Est-ce récurrent ? (s'appliquera la prochaine fois qu'on touche ce type de fichier)
- Est-ce ciblable ? (peut être scopé à un glob pattern)
- Si oui → propose une règle `.claude/rules/` avec glob, contenu, et demande d'approbation
- Un proposal à la fois, jamais écrit sans approbation utilisateur

## 17. Task tracking intégré

**Superpowers** : pas de tracking de progression des tâches.

**ops** : `TaskCreate` / `TaskUpdate` dans `/ops:implement` :
- Chaque tâche du plan est enregistrée comme Claude Code task
- Status mis à jour : `pending` → `in_progress` → `completed` / `cancelled`
- Survit à la compaction de contexte
- Vérification finale : aucune tâche laissée `in_progress` ou `pending`

## 18. Resilience lens dans le code review

**Superpowers** : code review standard (correctness, quality, SOLID).

**ops** : dimension supplémentaire dans `code-reviewer` Step 4 :

> **Resilience** : Comment ce code échoue-t-il ? Que se passe-t-il avec un input inattendu, un timeout réseau, une ressource manquante, un accès concurrent ? L'échec est-il graceful ou catastrophique ?

Plus le **Carmack test** pour la readability : "le code aurait-il un sens sans les commentaires ?"

## 19. Spec reviewer "don't trust the report"

**Superpowers** : le spec-reviewer lit le spec et vérifie la complétude.

**ops** : instruction CRITICAL ajoutée :

> Do NOT trust the spec's claims. The spec may say "uses the existing auth middleware" — verify by reading the actual code referenced. Specs written from memory contain errors.

Le spec-reviewer doit vérifier les claims du spec contre le code source réel.

## 20. Cost optimization pragmatique

**Superpowers** : toujours 2-stage review (spec → quality). Pas de skip.

**ops** : skip explicite pour les tâches triviales :
- Code review : skip pour renaming, config value changes, comments
- Security reviewer : skip pour code non-sensible (config, docs, styles)
- Debug code review : skip pour fixes triviaux (typos, one-line corrections)

## 21. Instrumentation diagnostique avant hypothèses

**Superpowers** : 4 phases de debug, pas de phase d'instrumentation.

**ops** : Step 1.5 — si le chemin d'erreur traverse plusieurs composants :
1. Identifier les boundaries de composants
2. Ajouter du logging temporaire à chaque boundary (entrée/sortie, shape des données, timestamps)
3. Reproduire l'erreur avec instrumentation active
4. Lire l'output diagnostique — où les données divergent-elles ?

Narrowe l'investigation de "quelque part dans la stack" à "entre composant X et Y".

## 22. Subagent context rules explicites

**Superpowers** : "subagents receive only the context they need" (principe v5.0.2).

**ops** : 4 règles concrètes dans chaque skill :
1. **Provide content inline** — ne pas faire relire des fichiers déjà lus
2. **Scope the context** — donner le strict nécessaire (pas l'historique de session)
3. **Name what you provide** — labeler avec la source `[From file.yaml:15-42]`
4. **Let the agent explore beyond** — éviter les doublons, pas restreindre

## Résumé

| #   | Dimension              | ops                        | Superpowers             |
|-----|------------------------|----------------------------|-------------------------|
| 1   | Critic adversarial     | 7 phases                   | 1 reviewer basique      |
| 2   | Discovery handling     | 3 niveaux, 2 skills        | DONE_WITH_CONCERNS noté |
| 3   | Circuit breaker        | Diagnostic + 5 options     | Stoppe et rapporte      |
| 4   | Security reviewer      | Pipeline 2 étages          | Une ligne dans review   |
| 5   | Git intelligence       | 2 modes, 3 skills          | Rien                    |
| 6   | LSP detection          | 4 niveaux                  | Rien                    |
| 7   | LSP in review          | Diagnostics auto           | Rien                    |
| 8   | Debug workflow         | 8 étapes                   | 4 phases                |
| 9   | Non-deterministic bugs | Protocole dédié            | Rien                    |
| 10  | CLAUDE.md-driven tasks | Rules → tasks              | Convention only         |
| 11  | Conformity check       | Étape dédiée               | Implicite               |
| 12  | Research adequacy      | Quantitatif + preuves      | Yes/No subjectif        |
| 13  | Clarity gate           | What/Why/Success           | Explore d'abord         |
| 14  | Instruction priority   | 4 niveaux documentés       | 3 niveaux, 1 skill      |
| 15  | Learnings capture      | Template structuré         | Rien                    |
| 16  | Rule proposals         | Learnings → .claude/rules/ | Rien                    |
| 17  | Task tracking          | TaskCreate/TaskUpdate      | Rien                    |
| 18  | Resilience lens        | Dimension review dédiée    | Standard review         |
| 19  | Spec "don't trust"     | Vérification source        | Trust-based             |
| 20  | Cost optimization      | Skip trivial reviews       | Toujours full review    |
| 21  | Instrumentation debug  | Step 1.5 dédié             | Pas d'instrumentation   |
| 22  | Subagent context       | 4 règles concrètes         | Principe général        |
