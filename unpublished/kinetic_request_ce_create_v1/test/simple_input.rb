{
  'info' => {
    'api_server' => 'https://kinops.io',
    'api_username' => '',
    'api_password' => '',
    'space_slug' => '',
    'enable_debug_logging' => 'Yes'
  },
  'parameters' => {
    'error_handling' => 'Error Message',
    'space_slug' => '',
    'type' => 'form',
    'kapp' => 'services',
    'data' => ' {
    "anonymous": false,
    "attributes": [
      {
        "name": "Icon",
        "values": [
          "fa-tint"
        ]
      },
      {
        "name": "Owning Team",
        "values": [
          "Facilities"
        ]
      },
      {
        "name": "Task Assignee Team",
        "values": [
          "Facilities"
        ]
      }
    ],
    "bridgedResources": [],
    "categorizations": [
      {
        "category": {
          "slug": "facilities-general-office"
        }
      }
    ],
    "createdAt": "2017-04-14T18:04:27.137Z",
    "createdBy": "kdadmin@kinops.io",
    "customHeadContent": null,
    "description": "Request Cleaning",
    "fields": [
      {
        "name": "What needs cleaning"
      },
      {
        "name": "Description"
      },
      {
        "name": "Requested For"
      },
      {
        "name": "Requested For Display Name"
      },
      {
        "name": "Requested By"
      },
      {
        "name": "Requested By Display Name"
      },
      {
        "name": "Discussion Id"
      },
      {
        "name": "Observing Teams"
      },
      {
        "name": "Observing Individuals"
      },
      {
        "name": "Status"
      }
    ],
    "kapp": {
      "name": "Services",
      "slug": "services"
    },
    "name": "Cleaning2",
    "notes": null,
    "pages": [
      {
        "advanceCondition": null,
        "displayCondition": null,
        "displayPage": null,
        "elements": [
          {
            "type": "section",
            "renderType": null,
            "name": "Questions",
            "title": "Questions",
            "visible": true,
            "omitWhenHidden": null,
            "renderAttributes": {},
            "elements": [
              {
                "type": "field",
                "name": "What needs cleaning",
                "label": "What, specifically, needs cleaning?",
                "key": "f1",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": true,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Description",
                "label": "Detailed Description",
                "key": "f2",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 3
              }
            ]
          },
          {
            "type": "section",
            "renderType": null,
            "name": "Footer",
            "title": null,
            "visible": true,
            "omitWhenHidden": null,
            "renderAttributes": {
              "class": "text-right"
            },
            "elements": [
              {
                "type": "button",
                "label": "Save",
                "name": "Save",
                "visible": true,
                "enabled": true,
                "renderType": "save",
                "renderAttributes": {}
              },
              {
                "type": "button",
                "label": "Submit",
                "name": "Submit",
                "visible": true,
                "enabled": true,
                "renderType": "submit-page",
                "renderAttributes": {}
              }
            ]
          },
          {
            "type": "section",
            "renderType": null,
            "name": "Hidden System Questions Do Not Delete",
            "title": "Hidden System Questions Do Not Delete",
            "visible": false,
            "omitWhenHidden": false,
            "renderAttributes": {},
            "elements": [
              {
                "type": "field",
                "name": "Requested For",
                "label": "Requested For",
                "key": "f908",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Requested For Display Name",
                "label": "Requested For Display Name",
                "key": "f909",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Requested By",
                "label": "Requested By",
                "key": "f906",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Requested By Display Name",
                "label": "Requested By Display Name",
                "key": "f907",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Discussion Id",
                "label": "Discussion Id",
                "key": "f902",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              },
              {
                "type": "field",
                "name": "Observing Teams",
                "label": "Observing Teams",
                "key": "f904",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "json",
                "renderType": "checkbox",
                "choicesResourceName": null,
                "choicesRunIf": null,
                "choices": []
              },
              {
                "type": "field",
                "name": "Observing Individuals",
                "label": "Observing Individuals",
                "key": "f905",
                "defaultValue": null,
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "json",
                "renderType": "checkbox",
                "choicesResourceName": null,
                "choicesRunIf": null,
                "choices": []
              },
              {
                "type": "field",
                "name": "Status",
                "label": "Status",
                "key": "f901",
                "defaultValue": "Draft",
                "defaultResourceName": null,
                "visible": true,
                "enabled": true,
                "required": false,
                "requiredMessage": null,
                "omitWhenHidden": null,
                "pattern": null,
                "constraints": [],
                "events": [],
                "renderAttributes": {},
                "dataType": "string",
                "renderType": "text",
                "rows": 1
              }
            ]
          }
        ],
        "events": [],
        "name": "Page 1",
        "renderType": "submittable",
        "type": "page"
      }
    ],
    "securityPolicies": [],
    "slug": "cleaning2",
    "status": "Active",
    "submissionLabelExpression": "TEST",
    "type": "Service",
    "updatedAt": "2018-06-04T15:33:19.079Z",
    "updatedBy": "anne.ramey@kineticdata.com"
  }'
  }
}