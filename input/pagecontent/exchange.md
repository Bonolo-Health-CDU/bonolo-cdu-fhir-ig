Each prescription has one [CDU Fulfilment Task](StructureDefinition-cdu-fulfilment-task.html). The Task carries the CDU's progress in two fields:
- `Task.status` holds the FHIR lifecycle.
- `Task.businessStatus` holds what the facility sees.

The CDU writes both fields, and eRegister reads them back to update itself. All traffic goes through OpenHIM to the HAPI FHIR repository.

```
eRegister ──INT-01: POST transaction Bundle──────▶ OpenHIM ──▶ HAPI repository
   Patient, Practitioner, MedicationRequest,                     │ validates against
   Task (requested), allergies                                   │ these profiles
CDU Odoo  ──INT-02: GET Task?owner=…&status=requested ──────────┤ claims: accepted / received
          ──INT-03: updates the Task as the parcel moves ───────┤ … completed / collected
                                                                 │
eRegister ──INT-03 read back: GET Task?identifier=…,… ──────────┘ updates its own records
```

### The lifecycle when there are no issues

| Step | Who | `Task.status` | `Task.businessStatus` |
|---|---|---|---|
| [INT-01](#int-01-eregister-publishes-a-prescription): prescription published | eRegister | `requested` | none |
| [INT-02](#int-02-the-cdu-claims-the-work): claimed by the CDU | CDU | `accepted` | `received` |
| [INT-03](#int-03-the-cdu-publishes-progress): in production (batching, picking, dispensing, bagging and QA, boxing) | CDU | `in-progress` | `in-preparation` |
| Packed, waiting for the delivery run | CDU | `in-progress` | `ready-for-dispatch` |
| Handed to Collect & Go | CDU | `in-progress` | `dispatched` |
| **Collected by the patient** (confirmed by Collect & Go) | CDU | **`completed`** | **`collected`** |
| [Read back](#int-03-read-back-eregister-updates-itself) | eRegister | | |

eRegister reads the Task at every step, not only at the end, so the facility can see where its prescription is.

### Other outcomes

| Outcome | `Task.status` | `Task.businessStatus` | What happens next |
|---|---|---|---|
| Query | `on-hold` | `query-raised` | The CDU contacts the patient to resolve a detail. |
| Returned to facility | `rejected` | `returned-to-facility` | `statusReason` says why. The facility amends the MedicationRequest and sets the Task back to `requested`. |
| Returned uncollected | `failed` | `uncollected-returned` | Final. Collect & Go confirmed the parcel is back at the CDU. |
| Cancelled by the CDU | `cancelled` | `cancelled` | Final. |
| Cancelled by eRegister | `cancelled` | | eRegister cancels the MedicationRequest and the Task. The CDU stops if production hasn't started; otherwise a CDU administrator decides. |

### INT-01: eRegister publishes a prescription

The eRegister module sends one **transaction Bundle** per prescription. Either every entry is saved or none is. It holds:

| Entry | How many | Request |
|---|---|---|
| Patient | 1 | `POST`, `ifNoneExist=identifier=http://fhir.health.gov.ls/sid/eregister-id\|{eRegister ID}` |
| Practitioner (the prescriber) | 1 | `POST`, `ifNoneExist=identifier=http://fhir.health.gov.ls/sid/eregister-provider-uuid\|{provider UUID}` |
| MedicationRequest | 1 | `POST`, `ifNoneExist=identifier=http://fhir.health.gov.ls/sid/eregister-order-uuid\|{order UUID}` |
| Task | 1 | `POST`, `ifNoneExist=identifier=http://fhir.health.gov.ls/sid/cdu-fulfilment-task\|{order UUID}` |
| AllergyIntolerance | 0 or more | `PUT AllergyIntolerance?identifier=http://fhir.health.gov.ls/sid/eregister-allergy-uuid\|{allergy UUID}` |

- Each entry has a `urn:uuid:` **fullUrl**, so entries can reference each other before the server assigns real IDs. The server rewrites those references.
- **Leave out `id`** on the resources in the bundle. The server assigns IDs. With a conditional update, an `id` in the body would become the record's ID on the server.
- Every reference carries a `reference` (a `urn:uuid` or, for facilities and pickup points, `Organization/{code}` or `Location/pup-{code}`). A `display` alone is not accepted.
- **`ifNoneExist`** creates a record only if none with that identifier exists yet. A facility that re-sends after an outage therefore cannot create duplicates, and a patient or prescriber already on the server is reused.
- **Allergies use a conditional update** (`PUT` with a search URL) instead: it creates the record the first time and replaces it afterwards, so a later change of status, for example *resolved*, reaches the CDU.
- The MedicationRequest's `requester` points to the Practitioner entry. The CDU prints the prescriber's name on dispensing labels.
- The Task's identifier value is the **same UUID** as the prescription's order identifier, so there is exactly one Task per order.
- The Task starts as `status = requested`, with `requester` set to the originating facility and `owner` set to the CDU.

Example: [INT-01 prescription publication](Bundle-ExamplePublicationBundle.html).

#### Allergies

| eRegister records | Send |
|---|---|
| One or more allergies | One AllergyIntolerance per allergy, identified by its eRegister UUID |
| That the patient has **no known allergies** | One AllergyIntolerance coded SNOMED CT `716186003` *No known allergy* |
| Nothing about allergies | No AllergyIntolerance. The CDU shows allergies as *not recorded* |

#### Dates

The CDU works out how much medicine to supply from three dates, which must follow this order:

> `authoredOn` (prescription date) < requested pickup date < next clinical visit date

- **Requested pickup date:** the day the patient collects the CDU parcel, once the medicine given at the facility runs out. Leave the CDU time to produce and deliver it.
- **Next clinical visit date** (mandatory from 0.4.0): the CDU supplies medicine from the pickup date until this date.
- `dispenseRequest.expectedSupplyDuration` should cover the same period: from the requested pickup date to the next clinical visit.

#### What not to send

Send only the resources in the table above. Encounters, Observations, lab orders and other clinical data, such as viral load results or pregnancy status, are outside this contract and must not be sent to the repository (decision D4, data minimisation).

### INT-02: the CDU claims the work

The CDU polls for Tasks it owns that are still `requested`:

```
GET [base]/Task?status=requested&owner=Organization/LS-CDU-001
```

It claims each one by setting `status = accepted` and `businessStatus = received`. Example: [fulfilment Task claimed by the CDU](Task-ExampleClaimedTask.html).

The CDU polls on `status`, not `_lastUpdated`, because `_lastUpdated` can silently skip records that commit late.

### INT-03: the CDU publishes progress

As the prescription moves through the CDU, the CDU updates the same Task, following the tables above. The CDU publishes **only these state changes**. Internal steps, such as moving from picking to dispensing, don't change what the facility sees.

- `lastModified` is set on every update.
- When the CDU returns a prescription to the facility, `statusReason` carries the first reason as a code from [CDU Rejection Reasons](ValueSet-cdu-rejection-reason.html), with every reason in its text.
- When a parcel is collected or confirmed back at the CDU, the time goes in `executionPeriod.end`.
- Collected and returned-uncollected come only from statuses that Collect & Go has **confirmed**.

### INT-03 read back: eRegister updates itself

eRegister reads the Tasks back in two ways.

**One prescription**, for example to show on the patient's profile:

```
GET [base]/MedicationRequest?_id={id}&_revinclude=Task:focus
```

**Keeping up to date.** eRegister keeps the list of prescriptions it still considers open and asks for their Tasks by identifier, up to 50 per request. A comma means OR:

```
GET [base]/Task?identifier=http://fhir.health.gov.ls/sid/cdu-fulfilment-task|{order UUID 1},
    http://fhir.health.gov.ls/sid/cdu-fulfilment-task|{order UUID 2},…&_count=50
```

(Shown on two lines here for readability; the request is one URL.)

- **Don't filter on status**, for example `status:not=completed`. A Task that completes drops out of such a search, so eRegister would never learn that the parcel was collected.
- A prescription leaves the open list once its Task is **`completed`, `failed` or `cancelled`**.
- Keep polling `rejected` and `on-hold` Tasks: they are waiting for the facility or the patient.

What eRegister records when a prescription completes (for example dispensing history or the next pickup) is up to eRegister. This guide fixes only what it reads.

**Not yet in the contract: what was dispensed.** A Task says *that* the parcel was collected, not *what* was in it. Whether the CDU should also publish a MedicationDispense depends on whether eRegister needs the dispensed products. See open decision 9 on the [Home](index.html#open-decisions) page.

### Status values

`Task.businessStatus` is bound (required) to [CDU Fulfilment Status](ValueSet-cdu-fulfilment-status.html):

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
