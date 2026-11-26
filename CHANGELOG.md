# Changelog

Each release of the `ls.moh.bonolo.cdu` package. Breaking changes carry a migration note (see README, working agreement).

## 0.4.0 (draft, November 2026)

Shaped by eRegister's first test push on 24 November: the CDU needs the prescriber, allergies, visit type and next clinical visit date in the prescription bundle itself.

**Added**
- **Visit type:** extension `visit-type` on MedicationRequest, coded from the new `cdu-visit-type` code system: `new`, `revisit` (a continuing ART patient) or `restarted`. Optional.
- **Prescriber:** new profile *Bonolo Practitioner*, identified by `http://fhir.health.gov.ls/sid/eregister-provider-uuid` (the system eRegister already uses).
- **Allergies:** new profile *Bonolo Allergy Intolerance*, identified by `http://fhir.health.gov.ls/sid/eregister-allergy-uuid`. Zero or more per bundle, sent as conditional updates. "No known allergies" is SNOMED CT `716186003`; no allergy records means *not recorded*.
- **Exchange workflow page:** the full INT-01 bundle, the allergy rules, the order the three dates must follow, and what must not be sent.

**Breaking: `MedicationRequest.requester` is mandatory and must reference a Bonolo Practitioner.**
- *Migration:* add the prescriber to the bundle as a Practitioner entry (`POST` with `ifNoneExist` on the provider UUID) and point `requester` at its `urn:uuid`. A display-only requester, such as `{"display": "Super Man"}`, is now rejected.

**Breaking: the next clinical visit date is mandatory** (`nextClinicalVisitDate`, was `0..1`).
- *Migration:* always send the extension. The CDU can't calculate the days of supply without it.

**Breaking: every reference must carry `reference`.** Applies to the patient, prescriber, facility, pickup point and Task links. A reference with only a `display` was valid FHIR but useless to the CDU.
- *Migration:* none for a conforming sender; eRegister already sends references.

**Bundle entries carry no `id`.** The example bundle no longer sets one. The server assigns IDs.

Existing prescriptions on the repository keep their stored form. Only new writes and updates must follow 0.4.0.

## 0.3.0 (November 2026)

**Regimens.** `art-regimen` now holds 24 codes from the national regimen list, up from two: `1j 1k 1m 1n 1p 1q 2c 2d 2g 2i 2j 2k 2l 2m 2n 2o 2p 2s 4g 4h 4j 4l 5f 5g`. Displays use the national short form with slashes, for example `TDF/3TC/DTG` (was `TDF-3TC-DTG`).

Left out until confirmed with the MoH Pharmacy Directorate and the eRegister team:
- `5h`, which the list gives as both ABC/3TC/LPV/r and ABC/3TC/ATV/r.
- TDF/3TC/ATV/r, which the list gives without a code.

**Breaking: `1f` (TDF/3TC/EFV) removed.** It is not on the national list.
- *Migration:* a prescription coded `1f` is now rejected by the repository. eRegister must not send it until it is re-added. No data needs converting, because no live prescriptions exist yet.
- *Display change:* a message that sends `1j` with the old display `TDF-3TC-DTG` still validates on its code. The validator may warn about the display text.

## 0.2.0 (October 2026)

First packaged contract (`scripts/package.sh`). `Task.businessStatus` became optional (`0..1`), so a Task can be created as *requested* before the CDU sets a status. Examples for the *requested* and *claimed* Task.

## 0.1.0 (October 2026)

Initial guide with the definitions agreed in NAMING.md.
