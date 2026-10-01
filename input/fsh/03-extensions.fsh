// ---------------------------------------------------------------
// EXTENSIONS: data FHIR has no standard field for.
// Rule of thumb: look hard for a standard element first; only
// extend when nothing fits. Each extension below says why.
// ---------------------------------------------------------------

// Why: MedicationRequest has no element for "where the patient
// will collect". dispenseRequest.performer means WHO dispenses
// (the CDU), not WHERE the patient collects.
Extension: PickupPoint
Id: pickup-point
Title: "Pickup Point"
Description: "The collection point (pharmacy, e-locker, health post) chosen by the patient."
Context: MedicationRequest
* value[x] only Reference(Location)

// Why: the ART-094 "Next Drug Pickup Date" has no exact FHIR home.
// validityPeriod means something else (when the Rx is valid).
Extension: RequestedPickupDate
Id: requested-pickup-date
Title: "Requested Pickup Date"
Description: "The date by which the parcel must be available for collection."
Context: MedicationRequest
* value[x] only date

// Why: status must be routed back to the facility that prescribed.
// The facility is carried on the order, not inferred from the patient,
// because patients move between facilities.
Extension: OriginatingFacility
Id: originating-facility
Title: "Originating Facility"
Description: "The health facility whose eRegister instance authored this prescription."
Context: MedicationRequest
* value[x] only Reference(Organization)

// Why: the CDU calculates its days' supply from this date (next clinical
// appointment minus next pickup date). FHIR's Appointment resource would
// need a separate record for one date.
Extension: NextClinicalVisitDate
Id: next-clinical-visit-date
Title: "Next Clinical Visit Date"
Description: "Date of the patient's next clinical appointment at the facility."
Context: MedicationRequest
* value[x] only date
