// ---------------------------------------------------------------
// TERMINOLOGY: the agreed lists of codes.
// A CodeSystem DEFINES codes. A ValueSet SELECTS codes for a field.
// ---------------------------------------------------------------

// ---- ART regimens -------------------------------------------------
// Taken from the "Regimen Prescribed" column of the ART-094 report.
// The Pharmacy Directorate must own and complete this list.
CodeSystem: ArtRegimenCS
Id: art-regimen
Title: "ART Regimen Codes"
Description: "National ART regimen codes as used in eRegister."
* ^caseSensitive = true
* #1j "TDF-3TC-DTG" "Tenofovir / Lamivudine / Dolutegravir"
* #1f "TDF-3TC-EFV" "Tenofovir / Lamivudine / Efavirenz"

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
