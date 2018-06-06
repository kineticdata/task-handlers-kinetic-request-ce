{
  'info' => {
    'smtp_server' => 'smtp.gmail.com',
    'smtp_port' => '25',
    'smtp_tls' => 'true',
    'smtp_username' => 'testing@kineticdata.com',
    'smtp_password' => '',
    'smtp_from_address' => 'testing@kineticdata.com',
    'api_server' => 'http://localhost:8080/kinetic',
    'api_username' => 'testing@kineticdata.com',
    'api_password' => '',
    'space_slug' => 'test',
    'enable_debug_logging' => 'Yes'
  },
  'parameters' => {
    'recipient_json' => '{"region":"test","type":"user","username":"john.doe@kineticdata.com","smtpaddress":"john.doe@kineticdata.com","language":"EN","email notifications":"yes"}',
    'notification_template_name' => 'Task Created - Approval Subtask',
    'date_format_slug' => 'notification-template-dates',
    'space_slug' => '',
    'admin_kapp_slug' => 'admin',
    'replacement_values' => '{"submission":{"id":"c926999a-ef24-11e6-8a56-b9f4d018f4bf"},"form":{"Form Status":"Active","Form Slug":"admin-workflow-errors","Form Name":"Admin Workflow Errors","Form Description":"This work order is designed for resolving workflow errors in the Kinops Task Engine","Form Notes":null},"kapp":{"Kapp Slug":"queue","Kapp Name":"Queue"},"space":{"Space Slug":"space-template"},"values":{"Requested By Display Name":"System Workflow","Requested For":"System Workflow","Requested For Display Name":"System Workflow","Details":"The kinetic_request_ce_submission_retrieve_v1 handler failed while trying to execute. The following reason was given for this failure: 404: Unable to locate the c2a1719e-ef24-11e6-9ac0-1343d5759328 Submission","Summary":"Workflow Error using the kinetic_request_ce_submission_retrieve_v1 handler","Inputs JSON":"{\"Space Slug\":null,\"Submission Id\":\"c2a1719e-ef24-11e6-9ac0-1343d5759328\"}","Run Id":"243","Handler Name":"kinetic_request_ce_submission_retrieve_v1","Error Message":"404: Unable to locate the c2a1719e-ef24-11e6-9ac0-1343d5759328 Submission","Status":"Open","Due Date":"2017-02-11T00:06:35+00:00","Assigned Team":"Administrators","Assigned Team Display Name":"Administrators","Deferral Token":"ec0ce5e9d9c6a70acfe3911a43260cd02073d096","Requested By":"System Workflow"},"formAttributes":{},"kappAttributes":{"Icon":"fa-list-ul","Notification Template Name":"Task Created","Queue Completed Value":"Resolution","Queue Details Value":"Details","Queue Filters":"{\"name\":\"My Open\",\"qualifications\":[{\"field\":\"coreState\",\"value\":\"Draft\"},{\"field\":\"values[Assigned Individual]\",\"value\":\"${me}\"}],\"order\":0}","Queue Group Base":"","Queue Name":"System Administration","Queue Setup Visible":"true","Queue Summary Value":"Summary","Queue Type":"Work Order"},"spaceAttributes":{"Admin Kapp Slug":"admin","Approval Days Due":"3","Approval Form Slug":"approval","Background Image":"https://s3.amazonaws.com/kinops-public/registered-images/coffee.jpg","Catalog Kapp Slug":"catalog","Company Name":"Space Template","Disable Self Sign Up":"false","Footer Bundle Path":"space","Header Bundle Path":"space","Page Title Prefix":"kinops","Queue Kapp Slug":"queue","Response Server Url":"https://kinops.io/space-template/kinetic-response","Task Assignee Team":"Default","Task Days Due":"5","Task Form Slug":"work-order","Task Server Url":"https://kinops.io/space-template/kinetic-task","Task Source Name":"Kinetic Request CE","Teams Kapp Slug":"teams","Visible User Attributes":"{\"name\": \"Manager\", \"changeLinkUrl\": \"catalog/manager-change-request\"}","Web Server Url":"https://kinops.io"},"vars":{}}',
    'record_message' => 'true'
  }
}