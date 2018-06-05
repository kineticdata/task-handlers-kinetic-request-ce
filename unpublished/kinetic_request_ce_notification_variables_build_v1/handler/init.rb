# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeNotificationVariablesBuildV1
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
  end

  def execute
    space_slug = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    if @info_values['api_server'].include?("${space}")
      api_server = @info_values['api_server'].gsub("${space}", space_slug)
    elsif !space_slug.to_s.empty?
      api_server = @info_values['api_server']+"/"+space_slug
    else
      api_server = @info_values['api_server']
    end

    begin
      api_username    = URI.encode(@info_values["api_username"])
      api_password    = @info_values["api_password"]
      error_handling  = @parameters["error_handling"]
      kapp_slug       = @parameters["kapp_slug"].empty? ? nil : @parameters["kapp_slug"]
      form_slug       = @parameters["form_slug"].empty? ? nil : @parameters["form_slug"]
      submission_id   = @parameters["submission_id"].empty? ? nil : @parameters["submission_id"]
      username        = @parameters["username"].empty? ? nil : URI.encode(@parameters["username"])
      backups         = @parameters["backups"].empty? ? nil : JSON.parse(@parameters["backups"])
      addt_vars       = @parameters["addt_vars"].empty? ? nil : JSON.parse(@parameters["addt_vars"])
      api_route       = "#{api_server}/app/api/v1/"
      api_context     = nil

      # Build up initial Variable Placeholder
      @variables =  {}
      variableTypes = [
                        "submission",
                        "values",
                        "form",
                        "formAttributes",
                        "kapp",
                        "kappAttributes",
                        "space",
                        "spaceAttributes",
                        "vars",
                        "user",
                        "userAttributes",
                        "userProfileAttributes"
                      ]
      variableTypes.each do |var|
        @variables[var] = {}
      end

      ######################################################
      ### BEGIN Build Up API Routes and Route Contexts   ###
      ######################################################

      if !submission_id.nil?
        data_api_route = api_route + "submissions/#{submission_id}?include=details,origin,parent,type,values,form,form.attributes,form.kapp,form.kapp.attributes,form.kapp.space,form.kapp.space.attributes"
        api_context = "Submission"
      elsif !form_slug.nil? && !kapp_slug.nil?
        data_api_route = api_route + "kapps/#{kapp_slug}/forms/#{form_slug}?include=details,attributes,kapp,kapp.attributes,kapp.space,kapp.space.attributes"
        api_context = "Form"
      elsif !kapp_slug.nil?
        data_api_route = api_route + "kapps/#{kapp_slug}?include=details,attributes,space,space.attributes"
        api_context = "Kapp"
      else
        data_api_route = api_route + "space?include=attributes,details"
        api_context = "Space"
      end

      if !username.nil?
        user_api_route = api_route + "users/#{username}?include=attributes,profileAttributes,details"
      end

      ######################################################
      ### END Build Up API Routes and Route Contexts   ###
      ######################################################

      # Get Data for Variable Replacements
      resource = RestClient::Resource.new(data_api_route, { :user => api_username, :password => api_password })
      response = resource.get

      # Build the results to be returned by this handler
      if response.nil?
        puts "NIL RESPONSE" if @enable_debug_logging
        <<-RESULTS
        <results>
          <result name="Handler Error Message"/>
          <result name="Replacement Variables">#{escape(@variables.to_json)}</result>
        </results>
        RESULTS
      else
        # Parse the Results returned from the API
        results = JSON.parse(response)

        if api_context == "Submission"
          buildSubmissionVariables(results)
        elsif api_context == "Form"
          buildFormVariables(results)
        elsif api_context == "Kapp"
          buildKappVariables(results)
        else
          buildSpaceVariables(results)
        end

        # Build Up User / User Attribtues / User Profile Attributes
        if !username.nil?
          resource = resource = RestClient::Resource.new(user_api_route, { :user => api_username, :password => api_password })
          response = resource.get
          if !response.nil?
            buildUserVariables(JSON.parse(response))
          end
        end

        # Add Addtl Variables
        if !addt_vars.nil?
          @variables["vars"] = addt_vars
        end

        # Check for Backups if supplied
        if !backups.nil?
          # Loop over Each Backup Key (kapp / submission / values / user...etc)
          backups.keys.each do |key|
            # If the backup is a valid property of what variables are expected
            if !@variables[key].nil?
              # Loop over each backup value supplied and check if it exists
              backups[key].each do |k,v|
                # If no value was found, use the backup value
                if @variables[key][k].nil? || @variables[key][k].empty?
                  @variables[key][k] = v
                end
              end
            end
          end
        end

        # Return Results
        <<-RESULTS
        <results>
          <result name="Handler Error Message"></result>
          <result name="Replacement Variables">#{escape(@variables.to_json)}</result>
        </results>
        RESULTS
      end

    rescue RestClient::Exception => error
      error_message = JSON.parse(error.response)["error"]
      if error_handling == "Raise Error"
        raise error_message
      else
        <<-RESULTS
        <results>
          <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
        </results>
        RESULTS
      end
    end
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  def buildSubmissionVariables(data)
    data = data['submission']
    data.keys.each do |key|
      # Build Up Submission Properties (non hash / arrays)
      if !data[key].is_a?(Hash) && !data[key].is_a?(Array)
        @variables['submission'][key] = data[key]
      end

      # Pass Form Object to the Build Form Variables Routine to Handle the Rest
      if key == "form"
        buildFormVariables({"form" => data[key]})
      end

      # Build Submission Values Variables
      if key == "values"
        @variables['values'] = data[key]
      end

    end
  end

  def buildFormVariables(data)
    data = data['form']
    data.keys.each do |key|
      # Build Up Form Properties (non hash / arrays)
      if !data[key].is_a?(Hash) && !data[key].is_a?(Array)
        label = "Form " + key.capitalize
        @variables['form'][label] = data[key]
      end

      # Build Attributes for this object
      if key == "attributes"
        data[key].each do |obj|
          @variables['formAttributes'][obj['name']] = obj['values'].join(', ')
        end
      end

      # Pass Kapp Object to the Build Kapp Variables Routine to Handle the Rest
      if key == "kapp"
        buildKappVariables({"kapp" => data[key]})
      end

    end
  end

  def buildKappVariables(data)
    data = data['kapp']
    data.keys.each do |key|
      # Build Up Kapp Properties (non hash / arrays)
      if !data[key].is_a?(Hash) && !data[key].is_a?(Array)
        label = "Kapp " + key.capitalize
        @variables['kapp'][label] = data[key]
      end

      # Build Attributes for this object
      if key == "attributes"
        data[key].each do |obj|
          @variables['kappAttributes'][obj['name']] = obj['values'].join(', ')
        end
      end

      # Pass Space Object to the Build Space Variables Routine to Handle the Rest
      if key == "space"
        buildSpaceVariables({"space" => data[key]})
      end

    end
  end

  def buildSpaceVariables(data)
    data = data['space']
    data.keys.each do |key|
      # Build Up Space Properties (non hash / arrays)
      if !data[key].is_a?(Hash) && !data[key].is_a?(Array)
        label = "Space " + key.capitalize
        @variables['space'][label] = data[key]
      end

      # Build Attributes for this object
      if key == "attributes"
        data[key].each do |obj|
          @variables['spaceAttributes'][obj['name']] = obj['values'].join(', ')
        end
      end

    end
  end

  def buildUserVariables(data)
    data = data['user']
    data.keys.each do |key|
      # Build Up User Properties (non hash / arrays)
      if !data[key].is_a?(Hash) && !data[key].is_a?(Array)
        @variables['user'][key] = data[key]
      end

      # Build Attributes for this object
      if key == "attributes"
        data[key].each do |obj|
          @variables['userAttributes'][obj['name']] = obj['values'].join(', ')
        end
      end

      # Build Profile Attributes for this object
      if key == "profileAttributes"
        data[key].each do |obj|
          @variables['userProfileAttributes'][obj['name']] = obj['values'].join(', ')
        end
      end

    end
  end

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
