# Bonolo Health CDU — Prescription Exchange Contract (FHIR R4)

This repository is the **contract** between eRegister and the CDU prescription repository: the exact shape of a prescription message, the codes it may carry, and the status values sent back. It is written in **FHIR Shorthand (FSH)** and compiled by **SUSHI** into standard FHIR JSON. The HAPI FHIR server later loads that JSON and rejects any message that breaks the contract.

**Browse the guide:** https://bonolo-health-cdu.github.io/bonolo-cdu-fhir-ig/ (rebuilt automatically on every merge to `main`).

> **Why start here and not with the server?** The contract is what both teams build against. If it is vague, eRegister and CDU each fill the gaps with their own assumptions, and those assumptions collide at integration. The server is only as strict as the profiles you give it.

---

## 1. Set up (30 minutes)

| Tool | Why | Install |
|---|---|---|
| Node.js 18+ | SUSHI runs on Node | https://nodejs.org |
| SUSHI | Compiles `.fsh` into FHIR JSON | `npm install -g fsh-sushi` |
| VS Code + **FHIR Shorthand** extension (by MITRE) | Syntax highlighting, jump-to-definition | VS Code Extensions panel, search "FHIR Shorthand" |
| Java 17+ (for exercise C and the website) | Runs the official HL7 validator and IG Publisher | https://adoptium.net |
| Ruby 3+ and Jekyll (for the website only) | The IG Publisher uses Jekyll to assemble the HTML | Mac: `brew install ruby`, then `$(brew --prefix)/opt/ruby/bin/gem install jekyll` |

Check it worked:

```bash
sushi --version        # expect SUSHI v3.x
```

**No install?** Paste any `.fsh` file into **FSH Online** (https://fshonline.fshschool.org) to experiment in the browser.

---

## 2. Build it

```bash
cd bonolo-cdu-fhir-ig
sushi build .
```

A good build ends with `0 Errors`. The output lands in `fsh-generated/resources/`: one JSON file per definition or example.

The first build downloads the FHIR R4 core package (~20 MB) into `~/.fhir/packages`. After that it works offline.

**Warning you can ignore:** *"Failed to load automatically-provided hl7.fhir.uv.tools / terminology / extensions"* only appears when the machine can't reach `packages.fhir.org`. On a normal connection it goes away.

**Two scripts build on top of SUSHI:**

| Script | Produces | When |
|---|---|---|
| `scripts/package.sh` | `output/ls.moh.bonolo.cdu-{version}.tgz`, the FHIR package HAPI loads | Each release. Same source and version give a byte-identical file. |
| `scripts/build-site.sh` | `site/`, the browsable guide. Open `site/index.html`; errors and warnings are in `site/qa.html` | To preview pages before a PR. CI publishes the real site on merge. |

`build-site.sh` downloads the HL7 IG Publisher (~240 MB) into `input-cache/` the first time, and needs internet access to fetch the page template and check codes. The narrative pages are in `input/pagecontent/`; the profile, code system and example pages are generated from the FSH.

---

## 3. Tour of the files

Read them in this order. Each one is commented line by line.

| File | What it contains | Maps to the architecture doc |
|---|---|---|
| `sushi-config.yaml` | Package name, FHIR version, canonical URL | — |
| `input/fsh/01-aliases.fsh` | Short names for identifier systems and URLs | §8 identifiers, D5 |
| `input/fsh/02-terminology.fsh` | Code lists: regimens, rejection reasons, external status | §8 regimen, §9 statuses, issue log 11–13 |
| `input/fsh/03-extensions.fsh` | Fields FHIR lacks: pickup point, requested pickup date, originating facility | §8 pickupPoint, nextPickupDate, facility |
| `input/fsh/04-profiles.fsh` | **The contract**: Patient, MedicationRequest, Task | §8 canonical contract, INT-01, INT-03 |
| `input/fsh/05-examples.fsh` | Synthetic examples, plus the full INT-01 transaction bundle | Test fixtures |

---

## 4. The ten concepts you need

1. **Resource**: a standard FHIR record type (`Patient`, `MedicationRequest`, `Task`).
2. **Profile**: a resource with your rules added. `BonoloMedicationRequest` is a `MedicationRequest` that *must* have an order ID, a regimen, a pickup point and so on.
3. **Cardinality**: how many times a field may appear. `0..1` optional, `1..1` mandatory, `0..*` optional and repeating, `0..0` forbidden.
4. **MustSupport (`MS`)**: the receiver must be able to store and handle this field, even if a given message leaves it out.
5. **CodeSystem vs ValueSet**: a CodeSystem *defines* codes (`#1j` = TDF/3TC/DTG). A ValueSet *selects* which codes are allowed in a field.
6. **Binding strength**: `required` means only codes from the ValueSet. `extensible` means use the ValueSet if a code fits, otherwise another code is allowed.
7. **Slicing**: splitting one repeating field into named parts. `Patient.identifier` holds several IDs; slicing names them `eRegister`, `national`, `hivProgram` and `clientRegistry`, and tells them apart by `system`.
8. **Identifier system**: the namespace an ID belongs to. `E0000000001/26` means nothing alone; with its system URL it's unambiguous across 150 facilities.
9. **Extension**: a field FHIR doesn't have. Add one only after checking that no standard element fits. Each extension file says why it exists.
10. **RuleSet**: a reusable block of rules, used in `05-examples.fsh` so the bundle and standalone examples share content.

---

## 5. Your first three exercises

Do these before changing anything real. Each takes about five minutes and teaches the edit-build-read loop.

**Exercise A: add a regimen.** In `02-terminology.fsh`, add a practice code under `ArtRegimenCS` (remove it afterwards):
```
* #9z "AZT/3TC/LPV/r" "Zidovudine / Lamivudine / Lopinavir-ritonavir"
```
Rebuild, then open `fsh-generated/resources/CodeSystem-art-regimen.json` and find your code.

**Exercise B: break the contract on purpose.** In `05-examples.fsh`, comment out the line `* authoredOn = …` in `PrescriptionContent` (put `//` in front). Rebuild. SUSHI will complain that a `1..1` element is missing. That's the contract doing its job. Put the line back.

**Exercise C: validate properly.** SUSHI checks structure; the official HL7 validator checks everything, including codes. Download `validator_cli.jar` from https://github.com/hapifhir/org.hl7.fhir.core/releases/latest, then:
```bash
java -jar validator_cli.jar fsh-generated/resources/Bundle-ExamplePublicationBundle.json \
  -version 4.0.1 -ig fsh-generated/resources
```
Aim for `Success: 0 errors`. The HAPI server will run this same validation on every incoming message.

---

## 6. How the pieces fit together at runtime

```
eRegister module ──POST transaction Bundle (INT-01)──▶ OpenHIM ──▶ HAPI repository
   Patient            ifNoneExist on eRegister ID                      │
   MedicationRequest  ifNoneExist on order UUID                        │ validates against
   Task (requested)   ifNoneExist on task ID                           │ these profiles
                                                                        ▼
CDU Odoo ──INT-02: GET Task?status=requested&owner=…──▶ claims (accepted / received)
         ──INT-03: updates status and businessStatus ──▶ … completed / collected
                                                                        │
eRegister module ──INT-03 read back: GET Task?identifier=…,… ───────────┘  updates itself
```

The full lifecycle, other outcomes and how eRegister polls are on the guide's **Exchange workflow** page (`input/pagecontent/exchange.md`).

- **Transaction bundle**: all three resources are saved together, or none are.
- **`ifNoneExist`**: create only if nothing with this identifier exists yet. A facility that re-sends after an outage cannot create duplicates.
- **`urn:uuid:` fullUrls**: temporary names that let entries reference each other before the server assigns real IDs.
- **Task**: the work-queue item. The CDU polls for `requested` Tasks rather than using `_lastUpdated`, which can silently skip late-committed records.

---

## 7. Open decisions encoded as placeholders

These are drafted so the build works. None is agreed. Each needs an owner and a decision before v1.0.

| # | Placeholder in this draft | Where | Decide with |
|---|---|---|---|
| 1 | Canonical URL and all `http://fhir.health.gov.ls/...` identifier systems | `sushi-config.yaml`, `01-aliases.fsh` | MoH ICT (national naming convention; check the client registry's existing systems first) |
| 2 | Regimen list: 24 national codes. Pending: `5h` (listed as two regimens), `TDF/3TC/ATV/r` (no code), `1f` (removed in 0.3.0; still prescribed?), and whether eRegister sends these codes (the list maps `4j` to eRegister's `1j`) | `02-terminology.fsh` | MoH Pharmacy Directorate, eRegister team |
| 3 | Prescription carries a **regimen code**, not discrete drugs | `04-profiles.fsh` | Depends on the eRegister spike: drug order or observation? |
| 4 | Pickup point is a `Location` referenced by code | `03-extensions.fsh` | Needs a coded pickup-point registry (currently free text) |
| 5 | Mandatory set: name, eRegister ID, order ID, authoredOn, regimen, pickup point, requested pickup date, originating facility | `04-profiles.fsh` | Architecture doc §8 says "six" but its table marks seven Yes; reconcile |
| 6 | Viral load and HIV diagnosis date are **excluded** | Not modelled | Decision D4 |
| 7 | Allergies not yet modelled (`AllergyIntolerance`) | — | Decision D4 |
| 8 | CDU identified as `LS-CDU-001` in the DHIS2 code system | Examples | Confirm the CDU's actual org unit code |
| 9 | The CDU reports *that* a parcel was collected (Task), not *what* was dispensed: no MedicationDispense profile | Not modelled | eRegister team: do they need the dispensed products? |

---

## 8. Working agreement

- The contract lives in Git. Any change goes through a pull request reviewed by **one person from each side** (eRegister and CDU).
- Bump `version` in `sushi-config.yaml` on every merged change. Breaking changes (making something mandatory, removing a code) bump the minor version and need a migration note.
- Examples are test fixtures. When you add a rule, add or update an example that exercises it.
- **Never commit real patient data.** Examples are synthetic.

---

## 9. What comes next

1. Close the placeholders in section 7, starting with the eRegister spike (#3), because it can reshape the MedicationRequest profile.
2. Share the browsable guide (link at the top) with the Ministry. Before calling it v1.0, clear the publishing warnings in `site/qa.html`: `experimental` flags and OIDs on the code systems and value sets.
3. Load the package into HAPI (step 2 of the sprint), switch on request validation, and POST the example bundle.
