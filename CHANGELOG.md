# Changelog

Each release of the `ls.moh.bonolo.cdu` package. Breaking changes carry a migration note (see README, working agreement).

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
