# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeNotificationTemplateSendV1

  # Include our helper
  include KineticRequestCeNotificationTemplateSendHandlerHelperV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Retrieve all of the handler info values and store them in a hash variable named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end

    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging

    # Retrieve the info values
    @smtp_server      =   @info_values['smtp_server']
    @smtp_port        =   @info_values['smtp_port'] || '25'
    @smtp_tls         =   @info_values['smtp_tls'].downcase == 'true'
    @smtp_username    =   @info_values['smtp_username']
    @smtp_password    =   @info_values['smtp_password']
    @smtp_from        =   @info_values['smtp_from_address']
    @api_username     =   URI.encode(@info_values['api_username'])
    @api_password     =   @info_values['api_password']
    @admin_kapp_slug  =   @parameters['admin_kapp_slug']

    @error_handling   = @parameters["error_handling"]

    # Create placeholder variables used throughout the handler
    @snippits         = []
    @snippit_re       = /\$\{snippit\(\'(.*?)\'\)}/
    @recipient_json   = {}
    @message          = {'email' => nil, 'subject' => nil, 'html' => nil, 'text' => nil}
    @replace_values   = JSON.parse(@parameters['replacement_values'])
    @replace_fields   = ['Subject', 'HTML Content', 'Text Content']
    @date_format_json = {}
    @error_message    = ''
    @template_name    = @parameters['notification_template_name']

  end

  # The execute method gets called by the task engine when the handler's node is processed. It is
  # responsible for performing whatever action the name indicates.
  # If it returns a result, it will be in a special XML format that the task engine expects. These
  # results will then be available to subsequent tasks in the process.
  def execute
    space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    if @info_values['api_server'].include?("${space}")
      @api_server = @info_values['api_server'].gsub("${space}", space_slug)
    elsif !space_slug.to_s.empty?
      @api_server = @info_values['api_server']+"/"+space_slug
    else
      @api_server = @info_values['api_server']
    end

    # Build Recipient JSON Based on input value. If not JSON, assume it's an email address
    begin
       @recipient_json = JSON.parse(@parameters["recipient_json"])
    rescue
       @recipient_json =  { "smtpaddress" => @parameters["recipient_json"], "type" => "smtp", "email notifications" => 'yes' }
    end

    # Build Up Template with Snippit Replacements
    template_to_use = mergeTemplateAndSnippits(@template_name)

    # Get Valid Date formats from CE
    getDateFormats()

    # Replace Content in Subject, HTML Body, Text Body if a Template was found
    template_to_use["Subject"] = apply_replacements(template_to_use["Subject"])
    template_to_use["HTML Content"] = apply_replacements(template_to_use["HTML Content"])
    template_to_use["Text Content"] = apply_replacements(template_to_use["Text Content"])

    ################################################
    ##  SEND EMAIL AND CREATE NOTIFICATION IN CE  ##
    ################################################

    # Check to make sure a valid message template was found
    if !template_to_use.nil?

      # If the User has an email address and want to receive notifications
      email_results = {}
      if !@recipient_json["smtpaddress"].to_s.empty? && @recipient_json["email notifications"].to_s.downcase != 'no'
        email_results = sendEmailMessage(template_to_use)
      else
        @error_message = @error_message + "\nNo Email Address or CE User was provided"
      end

      # Post Message to the Messages Form in CE
      notification_results = {}
      if @recipient_json["type"].to_s.downcase == 'user'
        notification_results = createNotification(template_to_use)
      end

      # Returning Results With Success
      results = "<results>\n"
      results += "  <result name='Handler Error Message'>#{escape(@error_message)}</result>\n"
      results += "  <result name='Email Id'>#{escape(email_results['message_id'])}</result>\n"
      results += "  <result name='Message Id'>#{escape(notification_results['submission_id'])}</result>\n"
      results += "</results>"
    else
      # Returning Results With Failure
      results = "<results>\n"
      results += "  <result name='Handler Error Message'>#{escape(@error_message)}</result>\n"
      results += "  <result name='Email Id'></result>\n"
      results += "  <result name='Message Id'></result>\n"
      results += "</results>"
    end
    return results
  end

  ##########################################################################
  ####  USED FOR RETRIEVING A RECORD BY NAME FROM CE NOTIFICATION DATA  ####
  ##########################################################################
  def mergeTemplateAndSnippits(templateName)
    puts "Merging Template and Snippit Records for #{templateName}" if @enable_debug_logging
    # Get the Initial Record
    record = getNotificationRecord(templateName)

    # Return nil if no Template was found
    if record.nil?
      return record
    else
    # Return Record with Snippits Replaced
      return replaceSnippitsInRecord(record)
    end
  end

  ##########################################################################
  ####  USED FOR RETRIEVING A RECORD BY NAME FROM CE NOTIFICATION DATA  ####
  ##########################################################################
  def getNotificationRecord(templateName)
    puts "Getting Notification Record: #{templateName}" if @enable_debug_logging
    # Build up a query to retrieve the appropriate notification template
    query = %|values[Name]="#{templateName}" AND values[Status]="Active"|
    # Build the API route for retrieving the notification template submissions based on the Query
    route =  "#{@api_server}/app/api/v1/kapps/#{@admin_kapp_slug}/forms/notification-data/submissions" +
                      "?include=details,values&limit=1000&q=#{URI.escape(query)}"
    # Build a rest resource for calling the CE API
    resource = RestClient::Resource.new(route, { :user => @api_username, :password => @api_password })
    # Retrieve template records from the CE API
    records = JSON.parse(resource.get)["submissions"]
    # Find the Record that matches the users preferences
    record = findClosestMatch(records, templateName)
    # Recursively Find all Snippits and Return the Final Content
    return record
  end


  ##########################################################################
  ####  METHOD USED FOR DETERMINING WHICH TEMPLATE / SNIPPIT TO CHOOSE  ####
  ##########################################################################
  def findClosestMatch(records, templateName)
    # Build a placeholder to store the selected notification template
    selected_record = nil
    recipient_language = @recipient_json['language'].to_s
    recipient_region = @recipient_json['region'].to_s

    # Return an error if no notification template was found
    if records.length == 0
      @error_message = "The following Notification Template or Snippit was not located: #{templateName}\n\n"
    # If only one template is returned, or the user has no preferences use the first match
    elsif records.length == 1 || (recipient_language.empty? && recipient_region.empty?)
        selected_record = records[0]['values']
        puts "Only one record returned for #{templateName}, OR no preferences found so selected first" if @enable_debug_logging
    else
    # Select a template based on users preferences
    # Define an array of preferences for each record returned
      recordPreferences = records.map do |record|
        {
          'id' => record['id'],
          'language' => record['values']['Language'],
          'region' => record['values']['Region'],
          'score' => 0,
        }
      end
      # Loop over each record and try to match it
      recordPreferences.each do |record|
        language = record['language'].to_s
        region = record['region'].to_s
        # Test to see if both language and region match if neither are empty
        if recipient_language == language && recipient_region == region && (!recipient_region.empty? && !region.empty?) && (!recipient_language.empty? && !language.empty?)
          record['score'] += 3
          puts "Matched on Language and Region for Template #{templateName}" if @enable_debug_logging
        # Test to see if a language matches if they are not empty
        elsif recipient_language == language && (!recipient_language.empty? && !language.empty?)
          record['score'] += 2
          puts "Matched on Language only for Template #{templateName}" if @enable_debug_logging
        # Test to see if a region matches
        elsif recipient_region == region && (!recipient_region.empty? && !region.empty?)
          record['score'] += 1
          puts "Matched on Region only for Template #{templateName}" if @enable_debug_logging
        end
        puts "Score is #{record['score']} for Template #{templateName}" if @enable_debug_logging
      end

      # Determine which record should be choosen as the selected record
      closestMatch = recordPreferences.max_by { |element| element['score'] }
      # Get the ID so we can select this record. If multiple had the same score, choose the first
      closestMatch.kind_of?(Array) ? closestMatch = closestMatch[0]['id'] : closestMatch = closestMatch['id']
      # Set the selected record to be returned
      selected_record = records.find { |match| match['id'] == closestMatch }['values']
    end
    # Return the selected record
    return selected_record
  end

  ##########################################################################
  ####     METHOD USED FOR REPLACING SNIPPITS IN A GIVEN NOTIFICATION   ####
  ##########################################################################
  def replaceSnippitsInRecord(record)
    puts "Replacing Snippits In Record" if @enable_debug_logging
    # Create a placeholder to store the
    snippitNames = []
    snippitRecords = []

    # Loop Over the Subject, HTML, Text of each Record and find Snippits if a value exists
    record.each do |field, value|
      if !value.nil?
        # Add Unique Snippits to the snippitNames Array
        value.scan(@snippit_re).flatten.uniq.each do |snippitName|
          snippitNames.push snippitName
        end
      end
    end

    # Retrieve Each Snippit Found from the CE API and store them in the snippitsRecords Array
    snippitNames.flatten.uniq.each do |snippitName|
      snippitRecords.push(getNotificationRecord(snippitName))
    end

    # Loop Over the Subject, HTML, Text of each Record and replace Snippits if they were found
    record.each do |field, value|
      if @replace_fields.include?(field) && !value.to_s.empty?
        value.scan(@snippit_re).flatten.uniq.each do |snippitName|
          # Do Rest Call to get Snippit
          snippitRecord = snippitRecords.find { |snippit| snippit != nil && snippit["Name"] == snippitName }
          # If a snippit record is found, replace it
          if !snippitRecord.to_s.empty?
            # If it's an HTML field, use the HTML Content from the Snippit
            if field.include? "HTML"
              record[field].gsub!("${snippit('#{snippitName}')}", snippitRecord["HTML Content"])
            else  # Otherwise, use the Text Content (Subject / Text)
              record[field].gsub!("${snippit('#{snippitName}')}", snippitRecord["Text Content"])
            end
          end
        end
      end
    end
    return record
  end

  ##########################################################################
  ####                  Perform Replacements.                           ####
  ##########################################################################
  def apply_replacements(content)
    puts "Applying Replacements for Content" if @enable_debug_logging
    #Extract the keys from the replacement_values attribute
    @replace_values.keys.each{|key|
      content = content.gsub(/\$\{#{key}\('(.*?)'\)\}/) do
        if @replace_values[key].has_key?($1)
          @replace_values[key][$1]
        else
          "${#{key}('#{$1}')}"
        end
      end
    }

    #Replace Dates
    #This does a "negative look ahead" to ensure it captures the entire quote string
    content = content.gsub(/\$\{appearance\('(.*?)'\)\}(?!('\)\}))/) do
      #need to split into content and ${format()} sections
      thisContent=$1.split("$")
      #check if tag matches a valid date and if so convert first part into date and format it.
      thisDateFormat = thisContent[1].gsub(/\{format\('(.*?)'\)\}/) do
        if @date_format_json.has_key?($1)
          @date_format_json[$1]['Format']
        else
          '${format(\''+$1+'\')}'
        end
      end
      if !thisDateFormat.nil? && !thisDateFormat.include?('{format')
        if thisDateFormat.include?('%')
          #turn original content into date and format it
          d = DateTime.parse(thisContent[0])
          d.strftime(thisDateFormat)
        end
      else
        '${appearance(\''+thisContent[0]+'$'+thisDateFormat+'\')}'
      end
    end

    return content
  end

  ##########################################################################
  ####                  Send Email using Template                       ####
  ##########################################################################
  def sendEmailMessage(template_to_use)
    puts "Sending Email Message to User" if @enable_debug_logging
    begin

      # Send out Message VIA SMTP
      to        = split_recipients(@recipient_json["smtpaddress"])
      subject   = template_to_use["Subject"]
      htmlbody  = template_to_use["HTML Content"]
      textbody  = template_to_use["Text Content"]

      # Create the new email object
      message = org.apache.commons.mail.HtmlEmail.new()

      # Set the required values
      message.setHostName(@smtp_server)
      message.setSmtpPort(@smtp_port.to_i)
      message.setTLS(@smtp_tls)

      # Unless there was not a user specified
      unless @smtp_username.nil? || @smtp_username.empty?
        # Set the email authentication
        message.setAuthentication(@smtp_username, @smtp_password)
      end

      # Set the subject
      message.setSubject(subject)

      # Set the email target values, these call special methods so that email
      # addresses provided with names (such as "John Doe <john.doe@domain.com>"
      # are properly parsed and configured).
      set_from(message, @smtp_from, @smtp_from)
      add_to(message, to)

      # Embed any images that are prefixed with "cid:" (this is calling a function
      # that is defined in smtp_email_send_handler_helper.rb)
      embed(message, htmlbody)

      # Set the plaintext message
      message.setTextMsg(textbody);

      # Send the email. As set in dependencies.rb, message send() returns a hash
      # containing: success (bool), id (str), exception (ex)
      message_response = message.send();

      if message_response["success"]
        message_id = message_response["id"]
        return {'message_id' => message_id, 'message_error' => nil}
      else
        unwrap_email_exception(message_response["exception"])
        return {'message_id' => message_id, 'message_error' => "There was an error sending the email message"}
      end
    rescue Exception => e
      if @error_handling == "Raise Error"
        raise
      else
        return {'message_id' => nil, 'message_error' => e.message}
      end
    end
  end

  ##########################################################################
  ####                        RECORD MESSAGE IN CE                      ####
  ##########################################################################
  def getDateFormats()
    puts "Getting Date Formats" if @enable_debug_logging
    begin
      # Retrieve all active date formats and populate the date_format_json object
      date_format_query = %|values[Status]="active"|
      date_format_api_route = "#{@api_server}/app/api/v1/kapps/#{@admin_kapp_slug}/forms/notification-template-dates/submissions" +
                  "?include=details,values&limit=1000&q=#{URI.escape(date_format_query)}"
      date_format_resource = RestClient::Resource.new(date_format_api_route, { :user => @api_username, :password => @api_password })
      date_format_response = date_format_resource.get
      JSON.parse(date_format_response)["submissions"].each{|format|
        @date_format_json[format["values"]["Name"]] = format["values"]
      }
      return true
    rescue RestClient::Exception => error
      puts "ERROR Getting Date Formats: #{error_message}" if @enable_debug_logging
      error_message = JSON.parse(error.response)["error"]
      if @error_handling == "Raise Error"
        raise error_message
      else
        @error_message = @error_message + "\nError Getting Date Formats: #{error.http_code}: #{escape(error_message)}"
        return false
      end
    end
  end


  ##########################################################################
  ####                        RECORD MESSAGE IN CE                      ####
  ##########################################################################
  def createNotification(template_to_use)
    puts "Creating Notification in CE for user" if @enable_debug_logging
    begin
      # Build up values to be sent to CE
      values = {
        "Status"        =>"Unread",
        "Username"      => @recipient_json["username"],
        "Kapp"          => !@replace_values.to_s.empty? && !@replace_values['kapp'].to_s.empty? ? @replace_values['kapp']['Kapp Slug'] : @admin_kapp_slug,
        "Title"         => template_to_use["Subject"],
        "Body"          => template_to_use["Text Content"],
        "Date Time Sent"=> Time.now().iso8601
      }

      # Building the object that will be sent to Kinetic Core
      data = {}
      data.tap do |json|
        json[:values] = values
      end

      # Post to the CE API
      api_route = "#{@api_server}/app/api/v1/kapps/#{@admin_kapp_slug}/forms/messages/submissions"
      resource = RestClient::Resource.new(api_route, { :user => @api_username, :password => @api_password })
      response = resource.post(data.to_json, { :accept => "json", :content_type => "json" })
      submission = JSON.parse(response)
      submission_id = submission['submission']['id']

      return {'submission_id' => submission_id, 'message_error' => nil}
    rescue RestClient::Exception => error
      error_message = JSON.parse(error.response)["error"]
      if @error_handling == "Raise Error"
        raise error_message
      else
        puts "Error thrown While Creating Message in CE for User" if @enable_debug_logging
        @error_message = @error_message + "\nCreating Notifiation For User: #{error.http_code}: #{escape(error_message)}"
        return {'submission_id' => nil, 'message_error' => "\nError Creating Notification: #{error.http_code}: #{escape(error_message)}"}
      end
    end
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end