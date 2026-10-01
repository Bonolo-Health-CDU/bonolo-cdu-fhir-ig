# Naming conventions: Bonolo CDU prescription exchange

**Status:** agreed 1 October 2026 (NUL technical team). Items marked **[to confirm]** are waiting on another team.
**Rule:** any new URL, identifier system or record-ID pattern is added to this file **before** it is used in code, FSH, Postman or HAPI configuration.

FHIR compares these strings character for character. A difference of one letter, `http` vs `https`, or a trailing slash makes a search return nothing, without an error. Copy them from here; never retype them.

---

## 1. Base addresses

| Purpose | Value | Notes |
|---|---|---|
| Things this project defines (profiles, extensions, code systems, value sets) | `http://fhir.health.gov.ls/bonolo-cdu` | **[to confirm]** with MoH ICT that `health.gov.ls` is the domain to use. The address does not need to resolve. |
| Identifier systems | `http://fhir.health.gov.ls/sid/` | Kept **outside** `/bonolo-cdu` on purpose: an eRegister ID or DHIS2 code is a national identifier, not a CDU concept, and other systems should be able to reuse these. |
| FHIR package id | `ls.moh.bonolo.cdu` | |

Use `http`, not `https`, exactly as written. This is a name, not a link.

---

## 2. Definitions (`{base}` = `http://fhir.health.gov.ls/bonolo-cdu`)

### Profiles
| Name | Canonical URL |
|---|---|
| Bonolo Patient | `{base}/StructureDefinition/bonolo-patient` |
| Bonolo CDU Medication Request | `{base}/StructureDefinition/bonolo-medication-request` |
| CDU Fulfilment Task | `{base}/StructureDefinition/cdu-fulfilment-task` |

### Extensions (all on MedicationRequest)
| Name | Canonical URL | Value |
|---|---|---|
| Pickup point | `{base}/StructureDefinition/pickup-point` | Reference(Location) |
| Requested pickup date | `{base}/StructureDefinition/requested-pickup-date` | date |
| Originating facility | `{base}/StructureDefinition/originating-facility` | Reference(Organization) |
| Next clinical visit date | `{base}/StructureDefinition/next-clinical-visit-date` | date |

### Code systems and value sets
Each code system has a value set with the same id: `{base}/ValueSet/{id}`.

| Id | Code system URL | Used in |
|---|---|---|
| `art-regimen` | `{base}/CodeSystem/art-regimen` | MedicationRequest.medicationCodeableConcept. Codes = eRegister regimen codes (`1j`, `1f`, …). **[to confirm]** full list with Pharmacy. |
| `cdu-programme` | `{base}/CodeSystem/cdu-programme` | MedicationRequest.category (`ART`) |
| `cdu-fulfilment-status` | `{base}/CodeSystem/cdu-fulfilment-status` | Task.businessStatus |
| `cdu-rejection-reason` | `{base}/CodeSystem/cdu-rejection-reason` | Task.statusReason |
| `pickup-type` | `{base}/CodeSystem/pickup-type` | Location.type on pickup points |

Standard HL7 systems used as-is: `http://hl7.org/fhir/CodeSystem/task-code` (Task.code = `fulfill`), `http://snomed.info/sct`, `http://unitsofmeasure.org`.

---

## 3. Identifier systems

| Identifier | System | On | Source in eRegister / CDU | |
|---|---|---|---|---|
| eRegister ID | `http://fhir.health.gov.ls/sid/eregister-id` | Patient | Primary patient identifier. Unique nationally. | **[national]** |
| National ID | `http://fhir.health.gov.ls/sid/national-id` | Patient | Patient identifier (not held for all patients) | **[national]** |
| HIV programme ID | `http://fhir.health.gov.ls/sid/hiv-program-id` | Patient | identifier_type 5 | **[national]** |
| Client registry ID | `http://fhir.health.gov.ls/sid/client-registry-id` | Patient | MPI client sync | **[national]** |
| Facility (DHIS2 org unit code) | `http://fhir.health.gov.ls/sid/dhis2-org-unit` | Organization | OpenMRS location (to be added) | **[national]** |
| Prescription | `http://fhir.health.gov.ls/sid/eregister-order-uuid` | MedicationRequest | UUID of the Bonolo encounter | |
| Fulfilment task | `http://fhir.health.gov.ls/sid/cdu-fulfilment-task` | Task | Same value as the prescription's UUID | |
| Pickup point | `http://fhir.health.gov.ls/sid/pickup-point-code` | Location | Collect & Go location reference | |
| Allergy record | **[to decide]** | AllergyIntolerance | Decided with the allergy upsert fix | |

---

## 4. [national] identifiers: check before first real data

The facility eRegister instances already sync patients to the national client registry through OpenHIM, so the registry already sends eRegister IDs (and probably National and HIV programme IDs) under **some** system string. If it does, **its string replaces ours** in section 3, even though it won't follow our pattern. Otherwise the same patient would carry two different kinds of eRegister ID across the national systems.

Ask the client registry / HIE team for the exact system strings for:

- [ ] eRegister ID
- [ ] National ID
- [ ] HIV programme ID
- [ ] Client registry ID

Ask the eLMIS integration team:

- [ ] DHIS2 org unit code system string

Record each answer here with the date and who confirmed it.

---

## 5. Record IDs for shared reference data

References to facilities and pickup points point at **real records** (`Organization/…`, `Location/…`), not at identifiers alone. That lets HAPI check the target exists and lets searches use `_include`.

Record IDs are **formed from the code**, so any system can build a reference without a lookup:

| Record | ID rule | Example |
|---|---|---|
| Facility or CDU (Organization) | DHIS2 org unit code | `Organization/LS-TEST-FAC-001` |
| Pickup point (Location) | `pup-` + Collect & Go location reference | `Location/pup-TEST-001` |

FHIR IDs may contain only `A–Z a–z 0–9 - .` and up to 64 characters. Replace any other character (for example `_` or a space) with `-`. **[to confirm]** that DHIS2 org unit codes fit this rule, or switch the facility rule to the 11-character DHIS2 UID.

These records are written only by the registry role (OpenHIM channel *Reference data - registry admin*).

---

## 6. Changing this file

1. Open a pull request that edits this file first.
2. Get one reviewer from the eRegister side and one from the CDU side.
3. Update FSH aliases (`input/fsh/01-aliases.fsh`), the demo stack's Postman collection and any HAPI configuration in the same release.
4. Bump the IG version in `sushi-config.yaml`.

After the pilot starts, changing any string here means migrating stored data, not just editing files.
