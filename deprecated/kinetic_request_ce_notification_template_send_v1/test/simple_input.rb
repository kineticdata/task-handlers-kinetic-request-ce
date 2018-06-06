{
  'info' => {
    'smtp_server' => 'smtp.gmail.com',
    'smtp_port' => '25',
    'smtp_tls' => 'true',
    'smtp_username' => 'john.doe@kineticdata.com',
    'smtp_password' => '',
    'smtp_from_address' => 'john.doe@kineticdata.com',
    'api_server' => 'http://localhost:8080/kinetic',
    'api_username' => 'john.doe@kineticdata.com',
    'api_password' => '',
    'space_slug' => 'test',
    'enable_debug_logging' => 'Yes'
  },
  'parameters' => {
    'error_handling' => "Error Message",
    'recipient_json' => '{"region":"test","type":"user","username":"john.doe@kineticdata.com","smtpaddress":"john.doe@kineticdata.com","language":"EN","email notifications":"yes"}',
    'notification_template_name' => 'SLM - Task Routed To Default Team',
    'space_slug' => '',
    'admin_kapp_slug' => 'admin',
    'replacement_values' => '{"submission":{"closedAt":null,"closedBy":null,"coreState":"Submitted","createdAt":"2018-06-05T14:04:39.466Z","createdBy":"wally@kinops.io","currentPage":"Page 1","handle":"5CF23E","id":"63125152-68c9-11e8-9f22-0b60745cf23e","label":"2018-06-27T17:00:00+00:00 for KD MN office","origin":null,"sessionToken":null,"submittedAt":"2018-06-05T14:04:40.283Z","submittedBy":"wally@kinops.io","type":"Service","updatedAt":"2018-06-06T14:04:55.204Z","updatedBy":"wally@kinops.io"},"values":{"Other Information":"This is for the Product Security Updates Ruby Tuesday presentation by john.doe@kineticdata.com. Please provide a lunch and dessert.","Status":"In Progress","Discussion Id":"ae10b50a-78dc-409f-be46-88022796ed72","Observing Teams":["Catering"],"Requested By":"john.doe@kineticdata.com","Requested By Display Name":"James Davies","Requested For":"john.doe@kineticdata.com","Requested For Display Name":"James Davies","Date and Time Needed":"2018-06-27T17:00:00+00:00","Number of People Expected":"KD MN office","Assigned Team":"Default"},"form":{"Form Anonymous":false,"Form Description":"Need catering for your Kinetic Data event? Use this request","Form Name":"Catering Request","Form Slug":"catering-request","Form Status":"Active","Form Type":"Service"},"formAttributes":{"Icon":"fa-cutlery","Owning Team":"Catering","Task Assignee Individual":"test@kineticdata.com","Task Assignee Team":"Catering"},"kapp":{"Kapp Name":"Services","Kapp Slug":"services"},"kappAttributes":{"Approval Form Slug":"approval","Icon":"fa-book","Kapp Configuration Status":"true","Kapp Description":"Browse, request and check status of services","Notification Template Name - Complete":"Service Completed","Notification Template Name - Create":"Service Submitted","Owning Team":"Default, Default","Record Search History":"All","Service Days Due":"7","Shared Bridged Resource Form Slug":"shared-resources","Statuses - Active":"Awaiting Approval, In Progress, Pending Approval, Submitted","Statuses - Cancelled":"Cancelled","Statuses - Inactive":"Draft","Task Assignee Team":"Default","Task Form Slug":"work-order"},"space":{"Space Name":"Kinetic Data","Space Slug":"kinetic-data"},"spaceAttributes":{"Admin Kapp Slug":"admin","Alerts Form Slug":"alerts","Approval Form Slug":"approval","Catalog Kapp Slug":"services","Change Manager Form Slug":"manager-change-request","Disable Self Sign Up":"false","Discussion Id":"74abdbf8-d9f1-4729-9042-c88c31afa3f4","Discussion Server Url":"https://kinops.io/kinetic-data/kinetic-response","Feedback Form Slug":"feedback","Footer Bundle Path":"space","Header Bundle Path":"space","Help Form Slug":"help","Hidden Users Regex":".*@kinops.io$","Invite Others Form Slug":"kinops-invite-others","Libraries Bundle Path":"space","Queue Kapp Slug":"queue","Request Alert Form Slug":"kinops-request-an-alert","Service Days Due":"7","Suggest a Service Form Slug":"kinops-suggest-a-service","System Administrator Email":"john.doe@kineticdata.com","Task Assignee Team":"Default","Task Form Slug":"work-order","Task Server Space Slug":"kinetic-data","Task Server Url":"https://kinops.io/kinetic-data/kinetic-task","Task Source Name":"Kinetic Request CE","Theme Color Primary":"#d95900","Web Server Url":"https://kinops.io"},"vars":{"Percent Remaining":"50"},"user":{"allowedIps":"","createdAt":"2017-04-14T18:07:51.815Z","createdBy":"kdadmin@kinops.io","displayName":"James Davies","email":"john.doe@kineticdata.com","enabled":true,"preferredLocale":null,"spaceAdmin":true,"updatedAt":"2018-05-11T16:32:58.113Z","updatedBy":"john.doe@kineticdata.com","username":"john.doe@kineticdata.com"},"userAttributes":{"Manager":"test@kineticdata.com","Site":"ABC","Department":"","Organization":""},"userProfileAttributes":{"Guided Tour":"Services","Phone Number":"845-549-0586","Queue Personal Filters":"{\"name\"=>\"All Administratorsss\", \"slug\"=>\"\", \"type\"=>\"custom\", \"sortBy\"=>\"createdAt\", \"status\"=>[], \"teams\"=>[\"Administrators\"], \"assignments\"=>{\"mine\"=>true, \"teammates\"=>true, \"unassigned\"=>true, \"byIndividuals\"=>false, \"individuals\"=>[]}, \"dateRange\"=>{\"timeline\"=>\"createdAt\", \"preset\"=>\"\", \"custom\"=>false, \"start\"=>\"\", \"end\"=>\"\"}}, {\"name\"=>\"Cpltd last 30 sort closed at\", \"slug\"=>\"\", \"type\"=>\"custom\", \"sortBy\"=>\"closedAt\", \"status\"=>[\"Complete\"], \"teams\"=>[], \"assignments\"=>{\"mine\"=>true, \"teammates\"=>false, \"unassigned\"=>false, \"byIndividuals\"=>false, \"individuals\"=>[]}, \"dateRange\"=>{\"timeline\"=>\"updatedAt\", \"preset\"=>\"30days\", \"custom\"=>false, \"start\"=>\"\", \"end\"=>\"\"}}","First Name":"","Last Name":""}}',
    'record_message' => 'false'
  }
}
