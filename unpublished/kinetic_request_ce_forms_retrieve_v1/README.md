== Kinetic Request CE Forms Retrieve
Retrieves a form.

=== Parameters
[Space Slug]
  The slug of the Space.
[Kapp Slug]
  The slug of the Kapp the form is for.


=== Results
[Forms]
  JSON listing of the forms in the kapp.
[Handler Error Message]
  Error, if one is returned.
  

=== Detailed Description
This handler retrieves a json list of forms listed like:

[
    {
      "anonymous": false,
      "createdAt": "2016-10-05T17:44:26.005Z",
      "createdBy": "wally@kineticdata.com",
      "description": "Order Amazon things here.",
      "name": "Amazon Order",
      "notes": null,
      "slug": "amazon-order",
      "status": "Active",
      "submissionLabelExpression": "${form('name')}",
      "type": "Service",
      "updatedAt": "2016-12-09T22:38:02.965Z",
      "updatedBy": "user@kineticdata.com"
    },
    {
      "anonymous": false,
      "createdAt": "2017-01-11T19:09:55.851Z",
      "createdBy": "wally@kineticdata.com",
      "description": "",
      "name": "Chart",
      "notes": null,
      "slug": "chart",
      "status": "New",
      "submissionLabelExpression": null,
      "type": "Content",
      "updatedAt": "2017-01-19T20:50:17.462Z",
      "updatedBy": "wally@kineticdata.com"
    }
]

Note, this includes details, but not attributes, bridgedResources, categorizations, customHeadContent, fields, kapp, pages,  
or securityPolicies -- so this provides form information, but is not a form export or a way to retrieve details, fields, etc
off the forms.