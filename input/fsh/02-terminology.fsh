// ---------------------------------------------------------------
// TERMINOLOGY: the agreed lists of codes.
// A CodeSystem DEFINES codes. A ValueSet SELECTS codes for a field.
// ---------------------------------------------------------------

// ---- ART regimens -------------------------------------------------
// From the national regimen list (Regimens.xlsx, November 2026). The
// first digit appears to mark the population and line of treatment
// (1 adult first-line, 2 adult second-line, 4 and 5 paediatric), so
// the same drugs can carry several codes. [to confirm] with Pharmacy.
// Left out until confirmed:
//   - 5h: listed as both ABC/3TC/LPV/r and ABC/3TC/ATV/r
//   - TDF/3TC/ATV/r: listed without a code
//   - 1f (TDF/3TC/EFV): in 0.2.0, not on the national list
// To be checked against the regimen list eRegister actually sends:
// the national list maps 4j to eRegister's 1j=TDF-3TC-DTG.
// Products and pack sizes per regimen live in CDU Odoo, not here.
CodeSystem: ArtRegimenCS
Id: art-regimen
Title: "ART Regimen Codes"
Description: "National ART regimen codes as used in eRegister."
* ^caseSensitive = true
* #1j "TDF/3TC/DTG"       "Tenofovir / Lamivudine / Dolutegravir"
* #1k "ABC/3TC/DTG"       "Abacavir / Lamivudine / Dolutegravir"
* #1m "AZT/3TC/DTG"       "Zidovudine / Lamivudine / Dolutegravir"
* #1n "TDF/3TC/LPV/r"     "Tenofovir / Lamivudine / Lopinavir-ritonavir"
* #1p "ABC/3TC/LPV/r"     "Abacavir / Lamivudine / Lopinavir-ritonavir"
* #1q "AZT/3TC/LPV/r"     "Zidovudine / Lamivudine / Lopinavir-ritonavir"
* #2c "AZT/3TC/LPV/r"     "Zidovudine / Lamivudine / Lopinavir-ritonavir"
* #2d "TDF/3TC/LPV/r"     "Tenofovir / Lamivudine / Lopinavir-ritonavir"
* #2g "ABC/3TC/LPV/r"     "Abacavir / Lamivudine / Lopinavir-ritonavir"
* #2i "AZT/3TC/TDF/LPV/r" "Zidovudine / Lamivudine / Tenofovir / Lopinavir-ritonavir"
* #2j "TDF/3TC/DRV/r"     "Tenofovir / Lamivudine / Darunavir-ritonavir"
* #2k "ABC/3TC/DRV/r"     "Abacavir / Lamivudine / Darunavir-ritonavir"
* #2l "AZT/3TC/DRV/r"     "Zidovudine / Lamivudine / Darunavir-ritonavir"
* #2m "TDF/3TC/RAL"       "Tenofovir / Lamivudine / Raltegravir"
* #2n "AZT/3TC/RAL"       "Zidovudine / Lamivudine / Raltegravir"
* #2o "ABC/3TC/RAL"       "Abacavir / Lamivudine / Raltegravir"
* #2p "TDF/3TC/DTG"       "Tenofovir / Lamivudine / Dolutegravir"
* #2s "AZT/3TC/TDF/DTG"   "Zidovudine / Lamivudine / Tenofovir / Dolutegravir"
* #4g "AZT/3TC/LPV/r"     "Zidovudine / Lamivudine / Lopinavir-ritonavir"
* #4h "ABC/3TC/LPV/r"     "Abacavir / Lamivudine / Lopinavir-ritonavir"
* #4j "TDF/3TC/DTG"       "Tenofovir / Lamivudine / Dolutegravir"
* #4l "AZT/3TC/DTG"       "Zidovudine / Lamivudine / Dolutegravir"
* #5f "AZT/3TC/DTG"       "Zidovudine / Lamivudine / Dolutegravir"
* #5g "AZT/3TC/ATV/r"     "Zidovudine / Lamivudine / Atazanavir-ritonavir"

ValueSet: ArtRegimenVS
Id: art-regimen
Title: "ART Regimens"
Description: "Regimens a CDU prescription may carry."
* include codes from system ArtRegimenCS

// ---- Rejection reasons -------------------------------------------
// Taken directly from the CDU issue log items 11-13.
CodeSystem: CduRejectionReasonCS
Id: cdu-rejection-reason
Title: "CDU Rejection Reasons"
Description: "Why the CDU rejected or returned a prescription."
* ^caseSensitive = true
* #missing-demographics  "Missing patient demographic information"
* #missing-medicine      "Missing medicine information"
* #missing-clinical      "Missing patient clinical information"
* #missing-collection    "Missing medicine collection information"
* #duplicate             "Duplicate prescription"
* #out-of-stock          "Out of stock"

ValueSet: CduRejectionReasonVS
Id: cdu-rejection-reason
Title: "CDU Rejection Reasons"
Description: "Reasons that may accompany a rejected fulfilment Task."
* include codes from system CduRejectionReasonCS

// ---- External lifecycle status -----------------------------------
// Section 9 of the architecture document: what a facility sees.
CodeSystem: CduFulfilmentStatusCS
Id: cdu-fulfilment-status
Title: "CDU Fulfilment Status"
Description: "Externally published status of a CDU prescription."
* ^caseSensitive = true
* #received            "Received"            "The prescription reached the CDU and is being checked."
* #returned-to-facility "Returned to facility" "Action is required by the prescriber."
* #query-raised        "Query raised"        "The CDU is contacting the patient to resolve a detail."
* #in-preparation      "In preparation"      "The parcel is in production."
* #ready-for-dispatch  "Ready for dispatch"  "Packed and awaiting the delivery run."
* #dispatched          "Dispatched"          "En route to the collection point."
* #collected           "Collected"           "The patient collected the parcel."
* #uncollected-returned "Returned uncollected" "The parcel came back to the CDU uncollected."
* #cancelled           "Cancelled"           "The CDU will not fulfil this prescription."

ValueSet: CduFulfilmentStatusVS
Id: cdu-fulfilment-status
Title: "CDU Fulfilment Status"
Description: "Allowed values for Task.businessStatus."
* include codes from system CduFulfilmentStatusCS

// ---- Programme -----------------------------------------------------
// Carried in MedicationRequest.category. Only ART today.
CodeSystem: CduProgrammeCS
Id: cdu-programme
Title: "CDU Programme"
Description: "Clinical programme a CDU prescription belongs to; used for batching."
* ^caseSensitive = true
* #ART "Antiretroviral therapy"

ValueSet: CduProgrammeVS
Id: cdu-programme
Title: "CDU Programmes"
Description: "Programmes the CDU fulfils prescriptions for."
* include codes from system CduProgrammeCS

// ---- Pickup point type --------------------------------------------
// eRegister concept 6506 "Pick-up Locker Type". Held on the Location
// record, not sent with each prescription.
CodeSystem: PickupTypeCS
Id: pickup-type
Title: "Pickup Point Type"
Description: "Kind of collection point a patient can choose."
* ^caseSensitive = true
* #e-locker "E-locker"
* #retail-pharmacy "Retail pharmacy"
* #outreach-health-post "Outreach / health post"

ValueSet: PickupTypeVS
Id: pickup-type
Title: "Pickup Point Types"
Description: "Allowed values for Location.type on pickup points."
* include codes from system PickupTypeCS
