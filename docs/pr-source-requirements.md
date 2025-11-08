# Anforderungen an PR‑Quellen für vollständige Verifikation durch den GitHub Code Reviewer


Zweck

- Sicherstellen, dass alle Änderungen in einem Pull Request (PR) vollständig und eindeutig gegen die verwendeten Quellen verifiziert werden können.


Kurzanforderung

- Jede Änderung im PR muss mit einer oder mehreren eindeutigen Quellen im PR verknüpft werden. Quellen müssen so genau referenziert werden, dass Reviewer die Änderung gegen die Originalquelle nachprüfen können.


Welche Quellen sind zulässig

- Interne Dokumentation im selben Repository (z. B. docs/, README, Spezifikationen).

- Andere Repositories, die im Issue benannt worden sind (immer mit commit‑SHA oder Tag referenzieren).

- Externe offizielle Dokumente (z. B. RFCs, Standards, Bibliotheks‑Dokumentation).

- Dazu gehören explizit (Beispiele):

  - https://lua-api.factorio.com/

  - https://wiki.factorio.com/


Wie Quellen referenziert werden müssen (Kurzfassung)

- Immer direkte URL + Version/Commit‑SHA + relevanter Abschnitt oder Zeilenangabe.

- Für GitHub‑Repos: verwende blob‑URLs mit commit‑SHA, z. B.

  https://github.com/<owner>/<repo>/blob/<commit-sha>/path/file#L10-L25

- Für Dokumente: gib Seiten‑ oder Abschnittsnummer(n) an (z. B. PDF Seite 7, Abschnitt 2.1).


Empfohlenes Vorgehen

- Lege relevante Dokus ins Repo (docs/) oder verlinke konkret mit stable refs (SHA/Tag).

- Wenn externe/private Repos verwendet werden: verweise im PR auf das Issue, das diese Repos nennt.

- Verwende das PR‑Template und fülle den Abschnitt „Quellen / References“ vollständig aus.


Automatisierung / Durchsetzung

- Füge das PR‑Template (.github/pull_request_template.md) ins Repo.

- Optionaler Automatismus (empfohlen): GitHub Action, die prüft, ob die PR‑Beschreibung einen „Quellen / References“‑Abschnitt mit mindestens einer URL enthält und ob URLs commit‑SHA oder Tag enthalten. Wenn nicht, schlägt die Action fehl und der PR‑Status bleibt rot.


Warum diese Genauigkeit wichtig ist

- Stabile Referenzen sind Voraussetzung für reproduzierbare Verifikation durch automatisierte Reviewer.

- Vermeidet Missverständnisse und beschleunigt Reviews.


Kontakt / Fragen

- Für Fragen zur Policy öffne ein Issue im Repo.

---
