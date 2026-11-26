// ---------------------------------------------------------------
// PROFILES: the contract itself. A profile takes a base FHIR
// resource and tightens it: makes fields mandatory (1..1),
// forbids fields (0..0), fixes codes, and binds lists.
//
// Cardinality cheat sheet:  0..1 optional   1..1 mandatory
//                           0..* optional, many   0..0 forbidden
// "MS" = MustSupport: the receiver must be able to store/handle it.
// ---------------------------------------------------------------

// ================= PATIENT =================
Profile: BonoloPatient
Parent: Patient
Id: bonolo-patient
Title: "Bonolo Patient"
Description: "Patient as sent from eRegister to the CDU prescription repository."

// Identifier "slicing": one list, several named kinds of ID.
// We tell FHIR to tell the slices apart by their 'system' value.
* identifier 1..* MS
* identifier ^slicing.discriminator.type = #value
* identifier ^slicing.discriminator.path = "system"
* identifier ^slicing.rules = #open
* identifier contains
    eRegister 1..1 MS and
    national 0..1 MS and
    hivProgram 0..1 MS and
    clientRegistry 0..1 MS
* identifier[eRegister].system = $eRegisterId
* identifier[eRegister].value 1..1
* identifier[national].system = $nationalId
* identifier[hivProgram].system = $hivProgramId
* identifier[clientRegistry].system = $crId

* name 1..* MS
* name.family 1..1
* name.given 1..*
* gender MS
* birthDate MS
* telecom MS
* address MS
* managingOrganization MS

// Data minimisation (Principle P2, Decision D4): nothing clinical
// lives on the Patient. Photo and marital status are forbidden.
* photo 0..0
* maritalStatus 0..0

// ================= MEDICATION REQUEST =================
Profile: BonoloMedicationRequest
Parent: MedicationRequest
Id: bonolo-medication-request
Title: "Bonolo CDU Medication Request"
Description: "A prescription routed to the Central Dispensing Unit for fulfilment."

// The order UUID minted by eRegister: the idempotency key.
* identifier 1..1 MS
* identifier.system = $orderId
* identifier.value 1..1

* status MS          // active | cancelled | stopped ... (cancellation rides here)
* intent = #order
* subject 1..1 MS
* subject only Reference(BonoloPatient)
* subject.reference 1..1
* authoredOn 1..1 MS
// The prescriber, sent as a Practitioner in the same bundle. The CDU
// prints the name on dispensing labels.
* requester 1..1 MS
* requester only Reference(BonoloPractitioner)
* requester.reference 1..1   // a display-only requester is not enough

// Regimen is sent as a code. NOTE: if the eRegister spike shows real
// drug orders, this changes to discrete products per request.
* medication[x] only CodeableConcept
* medicationCodeableConcept 1..1 MS
* medicationCodeableConcept from ArtRegimenVS (required)

* dosageInstruction MS
* dosageInstruction.patientInstruction MS
* dispenseRequest MS
* dispenseRequest.expectedSupplyDuration MS
* dispenseRequest.numberOfRepeatsAllowed MS

* category MS
* category from CduProgrammeVS (extensible)

* extension contains
    PickupPoint named pickupPoint 1..1 MS and
    RequestedPickupDate named requestedPickupDate 1..1 MS and
    OriginatingFacility named originatingFacility 1..1 MS and
    NextClinicalVisitDate named nextClinicalVisitDate 1..1 MS and
    VisitType named visitType 0..1 MS

// ================= FULFILMENT TASK =================
// The work-queue item. One Task per MedicationRequest.
// CDU searches for Tasks with status=requested, claims them
// (status=accepted), and updates businessStatus as work progresses.
// eRegister reads the same Task to show status: that is INT-03.
Profile: CduFulfilmentTask
Parent: Task
Id: cdu-fulfilment-task
Title: "CDU Fulfilment Task"
Description: "Tracks fulfilment of one prescription by the CDU."

// Same value as the prescription's order UUID: one Task per order,
// and a re-sent bundle cannot create a second Task.
* identifier 1..1 MS
* identifier.system = $taskId
* identifier.value 1..1
* status MS
* businessStatus 0..1 MS
* businessStatus from CduFulfilmentStatusVS (required)
* statusReason MS
* statusReason from CduRejectionReasonVS (extensible)
* intent = #order
* focus 1..1 MS
* focus only Reference(BonoloMedicationRequest)
* focus.reference 1..1
* for 1..1 MS
* for only Reference(BonoloPatient)
* for.reference 1..1
* authoredOn 1..1 MS
* lastModified 1..1 MS
* code 1..1 MS
* code = $taskCode#fulfill
* requester 1..1 MS   // the originating facility
* requester only Reference(Organization)
* requester.reference 1..1
* owner 1..1 MS       // the CDU
* owner only Reference(Organization)
* owner.reference 1..1

// ================= PRACTITIONER =================
// The prescriber. eRegister sends it in the same bundle as the
// prescription, created once per provider (ifNoneExist).
Profile: BonoloPractitioner
Parent: Practitioner
Id: bonolo-practitioner
Title: "Bonolo Practitioner"
Description: "The eRegister provider who wrote a prescription."

* identifier 1..* MS
* identifier ^slicing.discriminator.type = #value
* identifier ^slicing.discriminator.path = "system"
* identifier ^slicing.rules = #open
* identifier contains eRegisterProvider 1..1 MS
* identifier[eRegisterProvider].system = $providerId
* identifier[eRegisterProvider].value 1..1
* name 1..* MS
* active MS

// ================= ALLERGY INTOLERANCE =================
// The patient's allergies, sent with each prescription so the
// dispensing pharmacist can check them.
//  - One record per allergy, identified by eRegister's allergy UUID.
//  - "No known allergies": one record coded SNOMED 716186003.
//  - No allergy records at all means "not recorded".
// eRegister sends them as conditional updates, so a later change of
// status (for example resolved) replaces the earlier record.
Profile: BonoloAllergyIntolerance
Parent: AllergyIntolerance
Id: bonolo-allergy-intolerance
Title: "Bonolo Allergy Intolerance"
Description: "An allergy, or the statement that the patient has no known allergies, as recorded in eRegister."

* identifier 1..1 MS
* identifier.system = $allergyId
* identifier.value 1..1
* clinicalStatus MS      // required by FHIR unless entered-in-error
* verificationStatus 1..1 MS
* code 1..1 MS
* patient 1..1 MS
* patient only Reference(BonoloPatient)
* patient.reference 1..1
* recordedDate MS
* criticality MS
* reaction MS
* reaction.manifestation MS
