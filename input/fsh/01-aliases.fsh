// ---------------------------------------------------------------
// Aliases: short names for the agreed URLs. NAMING.md at the
// repository root is the authority; change it there first, then here.
// Base: http://fhir.health.gov.ls/bonolo-cdu  (agreed 1 Oct 2026,
// pending MoH ICT confirmation of the domain).
// Systems marked [national] must be replaced by the client registry's
// existing strings if it already has them (see NAMING.md section 4).
// ---------------------------------------------------------------

// Identifier systems
Alias: $eRegisterId   = http://fhir.health.gov.ls/sid/eregister-id          // [national]
Alias: $nationalId    = http://fhir.health.gov.ls/sid/national-id           // [national]
Alias: $hivProgramId  = http://fhir.health.gov.ls/sid/hiv-program-id        // [national]
Alias: $crId          = http://fhir.health.gov.ls/sid/client-registry-id    // [national]
Alias: $facilityCode  = http://fhir.health.gov.ls/sid/dhis2-org-unit        // [national]
Alias: $orderId       = http://fhir.health.gov.ls/sid/eregister-order-uuid
Alias: $taskId        = http://fhir.health.gov.ls/sid/cdu-fulfilment-task
Alias: $pickupPointId = http://fhir.health.gov.ls/sid/pickup-point-code
Alias: $providerId    = http://fhir.health.gov.ls/sid/eregister-provider-uuid
Alias: $allergyId     = http://fhir.health.gov.ls/sid/eregister-allergy-uuid

// Standard HL7 code systems
Alias: $taskCode      = http://hl7.org/fhir/CodeSystem/task-code
Alias: $sct           = http://snomed.info/sct
Alias: $allergyClinical     = http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical
Alias: $allergyVerification = http://terminology.hl7.org/CodeSystem/allergyintolerance-verification
