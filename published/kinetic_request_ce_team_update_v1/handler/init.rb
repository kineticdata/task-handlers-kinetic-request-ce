# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeTeamUpdateV1
  # Prepare for execution by building Hash objects for necessary values and
  # validating the present state.  This method sets the following instance
  # variables:
  # * @input_document - A REXML::Document object that represents the input Xml.
  # * @info_values - A Hash of info names to info values.
  # * @parameters - A Hash of parameter names to parameter values.
  #
  # This is a required method that is automatically called by the Kinetic Task
  # Engine.
  #
  # ==== Parameters
  # * +input+ - The String of Xml that was built by evaluating the node.xml
  #   handler template.
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Retrieve all of the handler info values and store them in a hash variable named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Determine if debug logging is enabled.
    @debug_logging_enabled = @info_values['enable_debug_logging'] == 'Yes'
    puts("Logging enabled.") if @debug_logging_enabled
    
    # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end
  end

  # The execute method gets called by the task engine when the handler's node is processed. It is
  # responsible for performing whatever action the name indicates.
  # If it returns a result, it will be in a special XML format that the task engine expects. These
  # results will then be available to subsequent tasks in the process.
  def execute
    api_username      = URI.encode(@info_values["api_username"])
    api_password      = @info_values["api_password"]
    api_server        = @info_values["api_server"]
    space_slug        = @parameters["space_slug"].empty? ? @info_values["space_slug"] : @parameters["space_slug"]
    current_name  = @parameters["current_name"]
    error_handling  = @parameters["error_handling"]
    teamAttributeDefinitions = {}

    # Get Team Attribute Definitions from Space
    api_route = "#{api_server}/#{space_slug}/app/api/v1/teamAttributeDefinitions"

    puts "API ROUTE: #{api_route}" if @debug_logging_enabled

    resource = resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })
    response = resource.get
    if !response.nil?
      defs = JSON.parse(response)['teamAttributeDefinitions']
      defs.each { |definition| teamAttributeDefinitions[definition['name']] = definition['allowsMultiple'] }
    end

    # Get All Teams (the only way to get the current team is by slug, so we need to retrieve all and find the slug)
    api_route = "#{api_server}/#{space_slug}/app/api/v1/teams"
    resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })
    response = resource.get
    teams = JSON.parse(response)['teams']
    teamToUpdate = teams.find {|team| team["name"] == current_name }
    teamSlugToUpdate = nil
    response = nil
    if !teamToUpdate.nil?
      teamSlugToUpdate = teamToUpdate['slug']
      # Get the team to update
      api_route = "#{api_server}/#{space_slug}/app/api/v1/teams/#{teamSlugToUpdate}?include=details,attributes"
      resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })
      response = resource.get
    end

    if response.nil?
      <<-RESULTS
      <results>
        <result name="Handler Error Message"></result>
        <result name="Team Name"></result>
        <result name="Exists">false</result>
      </results>
      RESULTS
    else
      # Start Update Code
      api_route = "#{api_server}/#{space_slug}/app/api/v1/teams/#{teamSlugToUpdate}"
      resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })
      team = JSON.parse(response)["team"]

      # If Attributes are to be appended to exisiting attributes
      if @parameters["append_or_replace"]=="Append"
        # If new attributes are supplied process the values
        if !@parameters["attributes"].empty?
          current_attributes = team["attributes"]
          new_attributes = JSON.parse(@parameters["attributes"])
          # Iterate through each new attributes
          new_attributes.each do |new|
            # Initialize a value to assume no match was found
            match = false
            # Iterate through each currents attributes
            current_attributes.each do |current|

              # If the curent Attribute no longer exists in the space, remove it
              if teamAttributeDefinitions[current['name']].nil?
                team['attributes'].delete_if {|attr| attr['name'] == current['name']}
              else
                # If the new attribute already exists continue
                if current['name'] == new['name']
                  # Set flag to indicate the attribute exist in current list
                  match = true
                  # Iterate through each of the attributes values to check if it already exists
                  new['values'].each do |value|
                    # If the value doesn't already exist in attributes, add it
                    if !current['values'].include? value
                      # Push the new value if allows multiple is true
                      if !teamAttributeDefinitions[current['name']].nil? && teamAttributeDefinitions[current['name']]
                        current['values'].push(value)
                      else
                        # Otherwise, replace the current value with the new value
                        current['values'] = [value]
                      end
                    end
                  end
                end
              end
            end
            # If the attribute didn't exist add its values.
            if !match
              team["attributes"].push(new)
            end
          end
        end
 
      # Else Replace Attributes with existing Attributes
      else
        team["attributes"] = JSON.parse(@parameters["attributes"])
      end

      data = {}
      data.tap do |json|
        json[:description]       = @parameters["description"]                     if !@parameters["description"].empty?
        json[:name]              = URI.encode(@parameters["new_name"])            if !@parameters["new_name"].empty?
        json[:attributes]        = team["attributes"]                             if !@parameters["attributes"].empty?
      end

      team_name=current_name
      # If new_name is supplied set team_name to its value.
      if !@parameters["new_name"].empty?
        team_name=@parameters["new_name"]
      end

      resource.put(data.to_json, { :content_type => "json", :accept => "json" })

      <<-RESULTS
      <results>
        <result name="Team Name">#{escape(URI.encode(team_name) )}</result>
        <result name="Exists">true</result>
        <result name="Handler Error Message"></result>
      </results>
      RESULTS
    end

    rescue RestClient::Exception => error
      error_message = JSON.parse(error.response)["error"]
      if error_handling == "Raise Error"
        raise error_message
      else
        if error.http_code == 404
          <<-RESULTS
          <results>
            <result name="Exists">false</result>
            <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
          </results>
          RESULTS
        else
          <<-RESULTS
          <results>
            <result name="Exists">false</result>
            <result name="Handler Error Message">#{error.http_code}: #{escape(error_message)}</result>
          </results>
          RESULTS
        end
      end

  end


  def boolean(string)
    return true if string.downcase == "true" || string =~ (/(true|t|yes|y|1)$/i)
    return false if string.downcase == "false" || string.nil? || string =~ (/(false|f|no|n|0)$/i)
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
