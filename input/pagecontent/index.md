This guide is the **contract** between eRegister and the CDU prescription repository. It sets out the exact shape of a prescription message, the codes it may carry and the status values the CDU sends back. The HAPI FHIR repository validates every incoming message against these profiles and rejects any that break them.

<div class="dragon">
<p><b>Draft {{site.data.fhir.version}}.</b> Several identifiers and code lists are placeholders until the owners listed under <a href="#open-decisions">Open decisions</a> agree them. Build against them now, but expect them to change before version 1.0.</p>
</div>

### What a prescription carries

One prescription is sent as one transaction holding the resources below. See the [Exchange workflow](exchange.html).

| Resource | Profile | What it holds |
|---|---|---|
| Patient | [Bonolo Patient](StructureDefinition-bonolo-patient.html) | Name, eRegister ID (mandatory), and the national, HIV programme and client registry IDs when known |
| Practitioner | [Bonolo Practitioner](StructureDefinition-bonolo-practitioner.html) | The prescriber: name and eRegister provider UUID |
| MedicationRequest | [Bonolo CDU Medication Request](StructureDefinition-bonolo-medication-request.html) | Order UUID, prescriber, regimen code, supply duration, pickup point, requested pickup date, next clinical visit date, originating facility, visit type |
| Task | [CDU Fulfilment Task](StructureDefinition-cdu-fulfilment-task.html) | The work item the CDU claims, and the status the facility reads back |
| AllergyIntolerance (0 or more) | [Bonolo Allergy Intolerance](StructureDefinition-bonolo-allergy-intolerance.html) | Each recorded allergy, or one "no known allergies" record. None at all means allergies were not recorded |

MedicationRequest carries five extensions, because FHIR has no standard field for them:
- [Pickup Point](StructureDefinition-pickup-point.html)
- [Requested Pickup Date](StructureDefinition-requested-pickup-date.html)
- [Originating Facility](StructureDefinition-originating-facility.html)
- [Next Clinical Visit Date](StructureDefinition-next-clinical-visit-date.html)
- [Visit Type](StructureDefinition-visit-type.html): new, revisit (continuing ART) or restarted

The full list of profiles, code systems, value sets and examples is on the [Artifacts](artifacts.html) page.

### How to read a profile page

- **Cardinality** says how many times a field may appear: `0..1` optional, `1..1` mandatory, `0..*` optional and repeating, `0..0` forbidden.
- **MustSupport** (the red **S** flag) means the receiver must be able to store and handle the field, even when a given message leaves it out.
- **Binding**: `required` means only codes from the value set are allowed. `extensible` means use a code from the value set if one fits.
- The **Key Elements** tab shows only what this guide constrains. **Differential** shows only what changed from base FHIR. **Snapshot** shows the whole resource.

### Identifiers and URLs

FHIR compares system URLs character for character, so a one-letter difference makes a search return nothing, without an error. Copy them from [NAMING.md](https://github.com/Bonolo-Health-CDU/bonolo-cdu-fhir-ig/blob/main/NAMING.md) and never retype them. In short:

- Definitions live under `http://fhir.health.gov.ls/bonolo-cdu`.
- Identifier systems live under `http://fhir.health.gov.ls/sid/`. Examples are `.../sid/eregister-id` and `.../sid/eregister-order-uuid`.
- Facility and pickup-point records have IDs formed from their codes: `Organization/{DHIS2 org unit code}` and `Location/pup-{Collect & Go reference}`.

### Open decisions

| # | Placeholder in this draft | Decide with |
|---|---|---|
| 1 | Canonical URL and all `http://fhir.health.gov.ls/...` identifier systems | MoH ICT, after checking the client registry's existing systems |
| 2 | Regimen list: 24 national codes. Pending: `5h` (listed as two regimens), `TDF/3TC/ATV/r` (no code), `1f` (removed in 0.3.0; still prescribed?), and whether eRegister sends these codes (the list maps `4j` to eRegister's `1j`) | MoH Pharmacy Directorate, eRegister team |
| 3 | Prescription carries a **regimen code**, not discrete drugs | eRegister spike: drug order or observation? |
| 4 | Pickup point is a `Location` referenced by code | Needs a coded pickup-point registry |
| 5 | Mandatory field set on MedicationRequest | Reconcile with architecture document §8 |
| 6 | Viral load and HIV diagnosis date are excluded | Decision D4 |
| 7 | Allergies are sent with each prescription (added in 0.4.0). Pending: whether eRegister can send an explicit "no known allergies" | eRegister team, CDU pharmacy |
| 8 | CDU identified as `LS-CDU-001` | Confirm the CDU's actual DHIS2 org unit code |
| 9 | The CDU reports *that* a parcel was collected (Task), not *what* was dispensed (no MedicationDispense) | eRegister team: do they need the dispensed products? |

### Changing the contract

The source is FHIR Shorthand in [GitHub](https://github.com/Bonolo-Health-CDU/bonolo-cdu-fhir-ig). Any change goes through a pull request reviewed by one person from eRegister and one from the CDU, and bumps the version. All examples are synthetic. Never add real patient data.

### Related repositories

| Repository | What it holds |
|---|---|
| [bonolo-cdu-fhir-ig](https://github.com/Bonolo-Health-CDU/bonolo-cdu-fhir-ig) | The source of this guide |
| [bonolo-health-eregister-automation](https://github.com/Bonolo-Health-CDU/bonolo-health-eregister-automation) | The prescription repository that enforces this contract (HAPI FHIR behind OpenHIM, with Keycloak and an admin portal), and a Postman collection that runs every exchange end to end |
| [bahmni-docker](https://github.com/Bonolo-Health-CDU/bahmni-docker) | The CDU in Odoo. Its `cdu_eregister` module is the CDU side of this exchange. |
