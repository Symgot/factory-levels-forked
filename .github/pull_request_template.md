Title: [Kurz] Kurztitel der Änderung


Beschreibung

- Kurze Zusammenfassung der Änderung (1–3 Zeilen).


Motivation / Zweck

- Warum wird diese Änderung gemacht?


Änderungen

- Liste der betroffenen Komponenten/Module/Dateien (Pfad/Zeilen falls relevant).


Quellen / References (ERFORDERLICH)

- Jede Änderung muss mindestens eine Quelle enthalten. Quellen müssen so genau wie möglich referenziert werden (URL, Version oder Commit‑SHA, Abschnitt/Zeilen).

- Format für Quellen:

  - Typ: (intern / extern / issue / repo)

  - Titel / Kurzbeschreibung

  - URL (bei Repos: blob‑URL mit commit‑SHA oder tag, z. B. https://github.com/<owner>/<repo>/blob/<commit-sha>/path/file#L10-L20)

  - Relevanter Abschnitt/Zeilen/Paragraph

- Beispiel:

  - Typ: Interne Doku

    - https://github.com/<owner>/<repo>/blob/<commit-sha>/docs/design.md#api-contracts

  - Typ: Externe Spezifikation

    - OpenAPI Spec v3.1.0 — https://spec.openapis.org/oas/v3.1.0#parameter-object (Abschnitt 4.2)

  - Typ: Anderes Repo (verwendet in Issue #123)

    - https://github.com/<owner/other-repo>/blob/<commit-sha>/src/lib.py#L50-L80


Erklärung zur Verifikation (ERFORDERLICH)

- Beschreibe kurz, wie ein Reviewer (menschlich oder automatisiert) die Änderung gegen die referenzierten Quellen prüfen soll (z. B. "Vergleiche die Validierungsregeln in src/validator.py mit Abschnitt X in der Spezifikation").


Tests / CI

- Welche Tests wurden hinzugefügt/aktualisiert?

- Link zu Testfällen (Pfad oder blob‑URL mit commit‑SHA).


Zugriffsanforderungen (falls Quelle privat)

- Falls eine referenzierte Quelle in einem privaten Repo liegt: wer braucht Zugriff und warum? (z. B. Team-Name / GitHub-Handel)


Checklist (muss abgehakt sein)

- [ ] Alle genutzten Quellen sind in „Quellen / References“ verlinkt.

- [ ] Links enthalten commit‑SHA oder Versionsangabe (nicht nur Branch‑Namen).

- [ ] Relevante Abschnitte/Zeilen sind angegeben.

- [ ] Tests/CI angepasst oder verlinkt.

- [ ] Keine sensiblen/privaten Quellen ohne Berechtigungsangabe verlinkt.


Hinweis

- Vage Hinweise wie „siehe Doku“ sind nicht ausreichend. Jede Quelle muss konkret und reproduzierbar referenziert werden.

---
