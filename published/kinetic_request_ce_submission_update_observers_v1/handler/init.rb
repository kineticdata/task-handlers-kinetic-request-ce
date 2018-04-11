# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))

class KineticRequestCeSubmissionUpdateObserversV1
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
    error_handling  = @parameters["error_handling"]
    error_message = nil

    api_username     = URI.encode(@info_values["api_username"])
    api_password     = @info_values["api_password"]
    api_server       = @info_values["api_server"]
    submission_id    = @parameters["submission_id"]
    replace_existing = @parameters["replace_existing"].downcase || "false"
    requires_update  = false
    values = {}

    begin
      api_route = "#{api_server}/#{space_slug}/app/api/v1/submissions/#{submission_id}"

      # Build Resource to get submission values and form fields
      resource = RestClient::Resource.new("#{api_route}?include=values,form.fields", { :user => api_username, :password => api_password })
      result   = resource.get({ :accept => "json", :content_type => "json" })

      parsed_result = JSON.parse(result)

      coreState =  parsed_result['submission']['coreState']
      fields = parsed_result['submission']['form']['fields'].map { |f| f['name'] }
      values = parsed_result['submission']['values']

      new_observing_teams = @parameters['observing_teams']
      new_observing_individuals = @parameters['observing_individuals']

      updated_values = {}

      # Check if update is required for observing teams if Observing Teams field exists
      if fields.include?('Observing Teams') && !new_observing_teams.empty?
        existing_observing_teams = values['Observing Teams'] || []

        # Check to make sure observing teams was passed in as an array
        if new_observing_teams.start_with?("[")
          new_observing_teams = JSON.parse(new_observing_teams)
        else
          new_observing_teams = [new_observing_teams]
        end

        # Check to see if teams match exactly and a replacement should occur
        if new_observing_teams.sort != existing_observing_teams.sort && replace_existing != "false"
          updated_values["Observing Teams"] = new_observing_teams
          requires_update = true

        # Otherwise, check to see if the new observing teams exist and if not, add them
        elsif !(new_observing_teams.sort == (new_observing_teams & existing_observing_teams).sort)
          new_observing_teams = new_observing_teams | existing_observing_teams
          updated_values["Observing Teams"] = new_observing_teams
          requires_update = true

        # Otherise, ensure that there are no duplicates, and update if there are
        elsif existing_observing_teams.uniq.length != existing_observing_teams.length
          updated_values["Observing Teams"] = existing_observing_teams.uniq
          requires_update = true
        end
      end

      # Check if update is required for observing individuals if Observing Individuals field exists
      if fields.include?('Observing Individuals') && !new_observing_individuals.empty?
        existing_observing_individuals = values['Observing Individuals'] || []

        # Check to make sure observing teams was passed in as an array
        if new_observing_individuals.start_with?("[")
          new_observing_individuals = JSON.parse(new_observing_individuals)
        else
          new_observing_individuals = [new_observing_individuals]
        end

        # Check to see if individuals match exactly and a replacement should occur
        if new_observing_individuals.sort != existing_observing_individuals.sort && replace_existing == "true"
          updated_values["Observing Individuals"] = new_observing_individuals
          requires_update = true

        # Otherwise, check to see if the new observing individuals exist and if not, add them
        elsif !(new_observing_individuals.sort == (new_observing_individuals & existing_observing_individuals).sort)
          new_observing_individuals = new_observing_individuals | existing_observing_individuals
          updated_values["Observing Individuals"] = new_observing_individuals
          requires_update = true

        # Otherise, ensure that there are no duplicates, and update if there are
        elsif existing_observing_individuals.uniq.length != existing_observing_individuals.length
          updated_values["Observing Individuals"] = existing_observing_individuals.uniq
          requires_update = true
        end
      end

      if requires_update && coreState != 'Closed'
        # Building the object that will be sent to Kinetic Core
        data = {}
        data.tap do |json|
          json[:values] = updated_values
        end

        puts "DATA: #{data.to_json}" if @enable_debug_logging
        # Post to the API
        result = resource.put(data.to_json, { :accept => "json", :content_type => "json" })
      end
    rescue RestClient::Exception => error
      error_message = "#{error.http_code}: #{JSON.parse(error.response)["error"]}"
      raise error_message if error_handling == "Raise Error"
    rescue Exception => error
      error_message = error.inspect
      raise error if error_handling == "Raise Error"
    end

    return <<-RESULTS
    <results>
      <result name="Handler Error Message">#{escape(error_message)}</result>
    </results>
    RESULTS
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
