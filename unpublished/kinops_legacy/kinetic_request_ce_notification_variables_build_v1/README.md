== Kinetic Request CE Notification Variables Build
This handler builds up replacement variables for notifications sent using the Kinetic Request CE Notification Template Send handler.

=== Parameters
[Error Handling]
  Determine what to return if an error is encountered.  menu="Error Message,Raise Error"
[space_slug]
  The Slug of the Space to which we're finding replacement variables in
  (if not provided, the space slug configured in the handlers info values will be used)
[kapp_slug]
  The Slug of the Kapp which we're finding replacement variables in
  (not required in a submission ID provided / required if a forms_slug provided)
[form_slug]
  The Slug of the Form which we're finding replacement variables in
  (not required in a submission ID provided)
[submission_id]
  The Submission ID to find replacement variables in
  (if used, all replacement variables will come from this submissions parent form/kapp/space)
[username]
  If a username is provided (should only be VALID CE USERS), then User Details / User Attributes / User Profile Attributes will be returned
[Additional Variables]
  A JSON string of additional replacement variables that will be accessable in Notifications by referencing
  ${vars('variable name')}
  Format should be a JSON object of Key / Value Pairs
[Backup Variables]
  A JSON String of Backup Variables to be used in Replacements if Missing.
  For example, if we want to use a space attribute to build styling in a notification but
  the Space Attribute got deleted for some reason, values here will be used and must follow
  the same structure as the returned results
  ex. {
        "spaceAttributes":{
                            "Color Primary":"#666666"
                          }
      }

=== Results

[Handler Error Message] (if appropriate)
[Replacement Variables]
   A properly formatted Replacement Variables Structure which can be used in notifications. See below for details

=== EXAMPLE RESULT

{
  "submission": {
    "closedAt": null,
    "closedBy": null,
    "coreState": "Draft",
    "createdAt": "2017-02-18T14:31:55.932Z",
    "createdBy": "test@test.com",
    "currentPage": "Page One",
    "handle": "3b7676",
    "id": "ff813651-f5e6-11e6-82e0-5ba1593b7676",
    "label": "Marketing - Work Order",
    "sessionToken": null,
    "submittedAt": null,
    "submittedBy": null,
    "type": "Work Order",
    "updatedAt": "2017-02-18T14:31:55.932Z",
    "updatedBy": "test@test.com"
  },
  "values": {
    "Response GUID": null,
    "Assigned Individual": null,
    "Assigned Individual Display Name": null,
    "Due Date": "2017-02-25T14:31:55+00:00",
    "Assigned Team": "Marketing",
    "Assigned Team Display Name": "Marketing",
    "Deferral Token": "219ec223ff1950652247c5924be26cb648dc6e9b"
  },
  "form": {
    "Form Anonymous": false,
    "Form Description": "This queue item template is for items which will be created from service item submissions.",
    "Form Name": "Work Order",
    "Form Slug": "work-order",
    "Form Status": "Active",
    "Form Type": "Work Order"
  },
  "formAttributes": {

  },
  "kapp": {
    "Kapp Name": "Queue",
    "Kapp Slug": "queue"
  },
  "kappAttributes": {
    "Icon": "fa-list-ul",
    "Queue Setup Visible": "true",
    "Queue Summary Value": "Summary",
    "Queue Type": "Work Order"
  },
  "space": {
    "Sapp Name": "Test Template",
    "Sapp Slug": "test-template"
  },
  "spaceAttributes": {
    "Admin Kapp Slug": "admin",
    "Approval Form Slug": "approval"
  },
  "vars": {
    "testAddtlVar-NAME": "testAddtlVar-VALUE"
  },
  "user": {
    "createdAt": "2017-02-02T17:29:52.983Z",
    "createdBy": "admin",
    "displayName": "Joe Blow",
    "email": "test@kineticdata.com",
    "enabled": true,
    "preferredLocale": null,
    "spaceAdmin": true,
    "updatedAt": "2017-02-17T22:22:38.721Z",
    "updatedBy": "test@kineticdata.com",
    "username": "test@kineticdata.com"
  },
  "userAttributes": {
    "Manager": "test@kineticdata.com"
  },
  "userProfileAttributes": {
    "First Name": "Joe",
    "Last Name": "Blow"
  }
}
