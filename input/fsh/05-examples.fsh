// ---------------------------------------------------------------
// EXAMPLES: concrete instances that must conform to the profiles.
// They are the quickest way to check that the contract makes sense,
// and they become shared test fixtures for both teams.
// Every person and number below is SYNTHETIC. Never put real
// patient data in this repository.
//
// RuleSets are reusable blocks of rules. We use them so the same
// patient/prescription content appears in the standalone examples
// AND in the INT-01 bundle without copy-paste.
// ---------------------------------------------------------------

RuleSet: PatientContent
* identifier[eRegister].value = "E0000000001/26"
* identifier[hivProgram].value = "A0000001/01-26"
* name.family = "Testing"
* name.given = "Palesa"
* gender = #female
* birthDate = "1990-01-01"
* telecom.system = #phone
* telecom.value = "+26650000000"
* managingOrganization = Reference(Organization/LS-TEST-FAC-001)

RuleSet: PrescriptionContent
* identifier.system = $orderId
* identifier.value = "3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* status = #active
* intent = #order
* authoredOn = "2026-09-22T10:15:00+02:00"
* medicationCodeableConcept = ArtRegimenCS#1j "TDF/3TC/DTG"
* dosageInstruction.patientInstruction = "Take one tablet daily"
* dispenseRequest.expectedSupplyDuration = 180 'd' "days"
* dispenseRequest.numberOfRepeatsAllowed = 0
* category = CduProgrammeCS#ART
* extension[pickupPoint].valueReference = Reference(Location/pup-TEST-001)
* extension[requestedPickupDate].valueDate = "2026-10-06"
* extension[originatingFacility].valueReference = Reference(Organization/LS-TEST-FAC-001)
* extension[nextClinicalVisitDate].valueDate = "2027-03-22"
* extension[visitType].valueCodeableConcept = CduVisitTypeCS#revisit "Revisit"

RuleSet: PractitionerContent
* identifier[eRegisterProvider].value = "5b1f2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"
* active = true
* name.family = "Prescriber"
* name.given = "Thabo"

RuleSet: NoKnownAllergyContent
* identifier.system = $allergyId
* identifier.value = "7d9e0f1a-2b3c-4d5e-8f6a-7b8c9d0e1f2a"
* clinicalStatus = $allergyClinical#active
* verificationStatus = $allergyVerification#confirmed
* code = $sct#716186003 "No known allergy"
* recordedDate = "2026-09-22T10:15:00+02:00"

RuleSet: TaskContent
* identifier.system = $taskId
* identifier.value = "3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* status = #requested
* intent = #order
* authoredOn = "2026-09-22T10:15:00+02:00"
* lastModified = "2026-09-22T10:15:00+02:00"
* code = $taskCode#fulfill
* requester = Reference(Organization/LS-TEST-FAC-001)
* owner = Reference(Organization/LS-CDU-001)

// ---------------- Reference records ----------------
// Shared records both sides point at. Record IDs are formed from the
// code (NAMING.md section 5) so the eRegister module can build a
// reference without looking anything up.

Instance: LS-TEST-FAC-001
InstanceOf: Organization
Title: "Example: health facility"
Description: "A prescribing facility. Record ID = DHIS2 org unit code."
Usage: #example
* identifier.system = $facilityCode
* identifier.value = "LS-TEST-FAC-001"
* active = true
* name = "Test Health Centre"

Instance: LS-CDU-001
InstanceOf: Organization
Title: "Example: Central Dispensing Unit"
Description: "The CDU. Record ID = its DHIS2 org unit code."
Usage: #example
* identifier.system = $facilityCode
* identifier.value = "LS-CDU-001"
* active = true
* name = "Bonolo Health Central Dispensing Unit"

Instance: pup-TEST-001
InstanceOf: Location
Title: "Example: pickup point"
Description: "A collection point. Record ID = 'pup-' + Collect & Go location reference."
Usage: #example
* identifier.system = $pickupPointId
* identifier.value = "TEST-001"
* status = #active
* name = "Test Mall Collect&go"
* type = PickupTypeCS#e-locker
* address.district = "Maseru"

// ---------------- Standalone examples ----------------

Instance: ExamplePatient
InstanceOf: BonoloPatient
Title: "Example: CDU patient"
Description: "A synthetic patient enrolled for CDU collection."
Usage: #example
* insert PatientContent

Instance: ExamplePractitioner
InstanceOf: BonoloPractitioner
Title: "Example: prescriber"
Description: "The eRegister provider who wrote the example prescription."
Usage: #example
* insert PractitionerContent

Instance: ExampleNoKnownAllergy
InstanceOf: BonoloAllergyIntolerance
Title: "Example: no known allergies"
Description: "The patient has been asked and has no known allergies."
Usage: #example
* insert NoKnownAllergyContent
* patient = Reference(ExamplePatient)

Instance: ExampleMedicationRequest
InstanceOf: BonoloMedicationRequest
Title: "Example: ART prescription for CDU"
Description: "A 6-month ART refill routed to the CDU for collection at a pharmacy."
Usage: #example
* insert PrescriptionContent
* subject = Reference(ExamplePatient)
* requester = Reference(ExamplePractitioner)

Instance: ExampleTask
InstanceOf: CduFulfilmentTask
Title: "Example: fulfilment Task requested by eRegister"
Description: "The work item created alongside the prescription, waiting for the CDU."
Usage: #example
* insert TaskContent
* focus = Reference(ExampleMedicationRequest)
* for = Reference(ExamplePatient)

Instance: ExampleClaimedTask
InstanceOf: CduFulfilmentTask
Title: "Example: fulfilment Task claimed by the CDU"
Description: "The CDU has accepted the work item and marked it as received."
Usage: #example
* insert TaskContent
* status = #accepted
* businessStatus = CduFulfilmentStatusCS#received
* focus = Reference(ExampleMedicationRequest)
* for = Reference(ExamplePatient)

// ---------------- INT-01 publication bundle ----------------
// What the eRegister module will POST to the repository.
//  - type = transaction: all entries are saved, or none are.
//  - fullUrl = urn:uuid:...: a temporary name for each entry, so
//    entries can point at each other before the server has
//    assigned real ids. The server rewrites these references.
//  - ifNoneExist: "create only if no resource with this identifier
//    exists". This is what makes a re-send after an outage safe.
//  - Allergies use a conditional update (PUT with a search URL)
//    instead, so a later change of status replaces the record.

Instance: BundlePatient
InstanceOf: BonoloPatient
Usage: #inline
* insert PatientContent

Instance: BundlePractitioner
InstanceOf: BonoloPractitioner
Usage: #inline
* insert PractitionerContent

Instance: BundleMedicationRequest
InstanceOf: BonoloMedicationRequest
Usage: #inline
* insert PrescriptionContent
* subject.reference = "urn:uuid:8a1d9c6e-1f2b-4d3c-8e4f-5a6b7c8d9e01"
* requester.reference = "urn:uuid:5b1f2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"

Instance: BundleTask
InstanceOf: CduFulfilmentTask
Usage: #inline
* insert TaskContent
* focus.reference = "urn:uuid:3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* for.reference = "urn:uuid:8a1d9c6e-1f2b-4d3c-8e4f-5a6b7c8d9e01"

Instance: BundleNoKnownAllergy
InstanceOf: BonoloAllergyIntolerance
Usage: #inline
* insert NoKnownAllergyContent
* patient.reference = "urn:uuid:8a1d9c6e-1f2b-4d3c-8e4f-5a6b7c8d9e01"

Instance: ExamplePublicationBundle
InstanceOf: Bundle
Title: "Example: INT-01 prescription publication"
Description: "Transaction bundle sent by an eRegister instance for one prescription: patient, prescriber, prescription, fulfilment Task and the patient's allergy status."
Usage: #example
* type = #transaction
* entry[0].fullUrl = "urn:uuid:8a1d9c6e-1f2b-4d3c-8e4f-5a6b7c8d9e01"
* entry[0].resource = BundlePatient
* entry[0].request.method = #POST
* entry[0].request.url = "Patient"
* entry[0].request.ifNoneExist = "identifier=http://fhir.health.gov.ls/sid/eregister-id|E0000000001/26"
* entry[1].fullUrl = "urn:uuid:5b1f2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"
* entry[1].resource = BundlePractitioner
* entry[1].request.method = #POST
* entry[1].request.url = "Practitioner"
* entry[1].request.ifNoneExist = "identifier=http://fhir.health.gov.ls/sid/eregister-provider-uuid|5b1f2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"
* entry[2].fullUrl = "urn:uuid:3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* entry[2].resource = BundleMedicationRequest
* entry[2].request.method = #POST
* entry[2].request.url = "MedicationRequest"
* entry[2].request.ifNoneExist = "identifier=http://fhir.health.gov.ls/sid/eregister-order-uuid|3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* entry[3].fullUrl = "urn:uuid:c2e3f4a5-b6c7-4d8e-9f01-2a3b4c5d6e7f"
* entry[3].resource = BundleTask
* entry[3].request.method = #POST
* entry[3].request.url = "Task"
* entry[3].request.ifNoneExist = "identifier=http://fhir.health.gov.ls/sid/cdu-fulfilment-task|3f6c1a2e-7b44-4c1e-9a55-1d2f3e4a5b6c"
* entry[4].fullUrl = "urn:uuid:7d9e0f1a-2b3c-4d5e-8f6a-7b8c9d0e1f2a"
* entry[4].resource = BundleNoKnownAllergy
* entry[4].request.method = #PUT
* entry[4].request.url = "AllergyIntolerance?identifier=http://fhir.health.gov.ls/sid/eregister-allergy-uuid|7d9e0f1a-2b3c-4d5e-8f6a-7b8c9d0e1f2a"
