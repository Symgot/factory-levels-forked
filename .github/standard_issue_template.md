---
name: Standard Issue Template
about: Template für alle Issues im factory-levels-forked Repository
title: "[Typ] Kurztitel des Issues"
labels: []
assignees: []
---

## Titel: [Typ] Kurztitel des Issues

### Problembeschreibung / Feature-Request

- Kurze Zusammenfassung des Problems oder gewünschten Features (1–3 Zeilen).

### Motivation / Zweck

- Warum soll dieses Issue bearbeitet werden?
- Welchen Nutzen/Mehrwert bringt die Lösung?

### Betroffene Komponenten

- Liste der betroffenen Module/Dateien/Bereiche im Mod (Pfad/Zeilen falls bekannt).

### Quellen / References (ERFORDERLICH)

- Jedes Issue muss mindestens eine Quelle enthalten. Quellen müssen so genau wie möglich referenziert werden (URL, Version oder Commit‑SHA, Abschnitt/Zeilen).

- Format für Quellen:

  - Typ: (intern / extern / issue / repo / factorio-api / mod-portal)

  - Titel / Kurzbeschreibung

  - URL (bei Repos: blob‑URL mit commit‑SHA oder tag, z. B. https://github.com/<owner>/<repo>/blob/<commit-sha>/path/file#L10-L20)

  - Relevanter Abschnitt/Zeilen/Paragraph

- Beispiel:

  - Typ: Interne Doku
    - https://github.com/Symgot/factory-levels-forked/blob/<commit-sha>/docs/design.md#api-contracts

  - Typ: Factorio API Dokumentation
    - Factorio API 1.1.0 — https://lua-api.factorio.com/latest/LuaEntity.html#LuaEntity.surface (Property surface)

  - Typ: Ähnliches Issue
    - https://github.com/<owner/other-repo>/issues/123

### Erwartete Lösung

- Beschreibe kurz, wie die Lösung aussehen könnte oder welche Schritte zur Umsetzung nötig sind.
- Bei Bugs: erwartetes vs. aktuelles Verhalten beschreiben.

### Reproduktion / Testfälle (bei Bugs)

- Schritte zur Reproduktion des Problems.
- Factorio-Version und Mod-Version angeben.
- Relevante Savegame-Informationen oder Screenshots.

### Zugriffsanforderungen (falls Quelle privat)

- Falls eine referenzierte Quelle in einem privaten Repo liegt: wer braucht Zugriff und warum? (z. B. Team-Name / GitHub-Handle)

### Checklist (muss abgehakt sein)

- [ ] Alle genutzten Quellen sind in „Quellen / References" verlinkt.
- [ ] Links enthalten commit‑SHA oder Versionsangabe (nicht nur Branch‑Namen).
- [ ] Relevante Abschnitte/Zeilen sind angegeben.
- [ ] Problem/Feature ist klar beschrieben und reproduzierbar.
- [ ] Keine sensiblen/privaten Quellen ohne Berechtigungsangabe verlinkt.

#### Anweisungen für GitHub Coding Agent

**CRITICAL:** Der GitHub Coding Agent MUSS die `copilot-instructions.md` befolgen und:

1. **ALLE Aufgaben vollständig integrieren**: Alle genannten Aufgaben vollständig integrieren
2. **Eigenständigen Abgleich durchführen**: Automatische Validierung gegen offizielle API
3. **Universelle Einsetzbarkeit sicherstellen**: Mock-System muss für jegliche Mod verwendbar sein
4. **Branch verwenden**: Alle Änderungen im korrekten Branch durchführen

### Workflow-Hinweis

- Nach der Issue-Erstellung wird ein Basis-PR erstellt.
- Alle Dokumentation und Diskussion erfolgt im PR, nicht im Issue.
- Das Issue dient nur als Ausgangspunkt für die strukturierte Bearbeitung.

### Hinweis

- Vage Hinweise wie „siehe Doku" sind nicht ausreichend. Jede Quelle muss konkret und reproduzierbar referenziert werden.
- Dieses Issue wird nach PR-Erstellung geschlossen, alle weitere Kommunikation erfolgt im PR.

---
