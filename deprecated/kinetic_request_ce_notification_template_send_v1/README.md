== Kinetic Request CE Notification Template Send
Sends an email notification using a template defined in Kinetic Request CE

=== Parameters
[Error Handling]
  Determine what to return if an error is encountered.  menu="Error Message,Raise Error"
[Space Slug]
  The slug of the Space in which notificaitons and messages should be retrieved from
[Recipient JSON]
  A JSON object representing a user and their preferences including Email, Notification Preferences, Language & Region
  {"type":"user","username":"test@mycompany.com","smtpaddress":"test@mycompany.com","language":"- Default -","email notifications":"yes"} 
[Notification Template Name]
  The name of a valid notification TEMPLATE that is Active in Kinetic Request CE
[Admin Kapp Slug]
  The id of the Kapp that contains the notification forms. Defaults to: admin
[Replacement Values]
  JSON string of replacement values. Required to successfully apply replacements 
  to any notification template.  JSON keys can be 'form', 'values', and 'vars'.
[Record Message]
  True or False if Messages should be recorded in your spaces admin kapp in the messages form.
  Note that this form must already exist for this function to work. Defaults to: true

=== Results

[Handler Error Message] (if appropriate)
[Email Id]
  ID of the SMTP Message that was sent out
[Message Id]
  ID of the message that was created in CE if record message parameter was set to true

	   
== Details

This handler was designed to work with Kinetic Request CE's Admin Kapp. 
Before using this handler, you should have the following forms defined in your admin kapp.

Notifications (notifications) -- Console Page used for viewing, creating and modifying notification records.
Notification Data (notification-data) -- Stores notification templates / snippits
Messsages (messages) -- (Records Messages that were sent out to the user if Record Message is set to true)
Notification Template Dates (notification-template-dates)  -- Stores date formats used used within your messages


