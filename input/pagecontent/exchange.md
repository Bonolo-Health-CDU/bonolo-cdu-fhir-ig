Three interactions use the resources in this guide. All of them go through OpenHIM to the HAPI FHIR repository.

```
eRegister ──POST transaction Bundle (INT-01)──▶ OpenHIM ──▶ HAPI repository
   Patient            ifNoneExist on eRegister ID                │
   MedicationRequest  ifNoneExist on order UUID                  │ validates against
   Task (requested)   ifNoneExist on task ID                     │ these profiles
                                                                  ▼
CDU Odoo ──GET Task?status=requested&owner=…──▶ claims (accepted) ──▶ updates businessStatus
                                                                  │
eRegister ──GET Task?identifier=…─────────────────────────────────┘  (INT-03 status)
```

### INT-01: eRegister publishes a prescription

The eRegister module sends one **transaction Bundle** per prescription, holding a Patient, a MedicationRequest and a Task. Either all three are saved or none are.

- Each entry has a `urn:uuid:` **fullUrl**, so entries can reference each other before the server assigns real IDs. The server rewrites those references.
- Each entry has an **ifNoneExist** condition on its business identifier. A facility that re-sends after an outage therefore cannot create duplicates.
- The Task's identifier value is the **same UUID** as the prescription's order identifier, so there is exactly one Task per order.
- The Task starts as `status = requested`, with `requester` set to the originating facility and `owner` set to the CDU.

Example: [INT-01 prescription publication](Bundle-ExamplePublicationBundle.html).

| Entry | `request.ifNoneExist` |
|---|---|
| Patient | `identifier=http://fhir.health.gov.ls/sid/eregister-id\|{eRegister ID}` |
| MedicationRequest | `identifier=http://fhir.health.gov.ls/sid/eregister-order-uuid\|{order UUID}` |
| Task | `identifier=http://fhir.health.gov.ls/sid/cdu-fulfilment-task\|{order UUID}` |

To cancel a prescription, set `MedicationRequest.status` to `cancelled`.

### The CDU claims the work

The CDU polls for Tasks it owns that are still `requested`:

```
GET [base]/Task?status=requested&owner=Organization/LS-CDU-001
```

It claims each one by setting `status = accepted` and `businessStatus = received`. Example: [fulfilment Task claimed by the CDU](Task-ExampleClaimedTask.html).

The CDU polls on `status`, not `_lastUpdated`, because `_lastUpdated` can silently skip records that commit late.

### INT-03: eRegister reads the status

eRegister reads the Task for its order:

```
GET [base]/Task?identifier=http://fhir.health.gov.ls/sid/cdu-fulfilment-task|{order UUID}
```

It shows `Task.businessStatus` to the facility. When the CDU returns or rejects a prescription, `Task.statusReason` says why, from [CDU Rejection Reasons](ValueSet-cdu-rejection-reason.html).

### Status values

`Task.businessStatus` is bound (required) to [CDU Fulfilment Status](ValueSet-cdu-fulfilment-status.html). The CDU publishes **only these state changes**. Internal CDU steps such as picking, bagging and QA are not published.

| Code | Shown to the facility as | Meaning |
|---|---|---|
| `received` | Received | The prescription reached the CDU and is being checked. |
| `returned-to-facility` | Returned to facility | Action is required by the prescriber. |
| `query-raised` | Query raised | The CDU is contacting the patient to resolve a detail. |
| `in-preparation` | In preparation | The parcel is in production. |
| `ready-for-dispatch` | Ready for dispatch | Packed and awaiting the delivery run. |
| `dispatched` | Dispatched | En route to the collection point. |
| `collected` | Collected | The patient collected the parcel. |
| `uncollected-returned` | Returned uncollected | The parcel came back to the CDU uncollected. |
| `cancelled` | Cancelled | The CDU will not fulfil this prescription. |

The [code system page](CodeSystem-cdu-fulfilment-status.html) is the authoritative list.
