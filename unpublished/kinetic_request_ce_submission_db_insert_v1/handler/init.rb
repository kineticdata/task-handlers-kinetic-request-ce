# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), "dependencies"))
require 'logger'

class KineticRequestCeSubmissionDbInsertV1

#######################################################################################################
#
# initialize
#
# Prepare for execution by building Hash objects for necessary values and
# validating the present state.  This method sets the following instance
# variables when executed through the Kinetic Task engine:
# * @input_document - A REXML::Document object that represents the input Xml.
# * @info_values - A Hash of info names to info values.
# * @parameters - A Hash of parameter names to parameter values.
#
# This method sets the following instance variables when executed from a batch driver ruby script:
# *
# *
#
# This method always sets the following instance variables:
# * @db_column_size_limits - List of text/char columns and their max lengths
# * @kapp_fields - List of kapp fields that are applicable across all forms.
# * @table_temp_prefix - The prefix for a temporary table in the database.
#
# This is a required method that is automatically called by the Kinetic Task
# Engine.
#
# ==== Parameters
# * +input+ - The String of Xml that was built by evaluating the node.xml
#   handler template.
#
#######################################################################################################
  def initialize(input)

    @db_column_size_limits = {
      :anonymous    => 36,
      :closedBy     => 255,
      :columnName   => 128,
      :coreState    => 10,
      :createdBy    => 255,
      :fieldKey     => 8,
      :formField    => 4000,
      :formName     => 255,
      :formSlug     => 255,
      :id           => 36,
      :kappSlug     => 255,
      :parentId     => 36,
      :originId     => 36,
      :submittedBy  => 255,
      :tableName    => 128,
      :type         => 255,
      :updatedBy    => 255
    }
    @info_values = {}
    @kapp_fields = [
      "Assigned Individual",
      "Assigned Team",
      "Deferral Token",
      "Due Date",
      "Requested By",
      "Requested For",
      "Status"
    ]
    @parameters = {}
    @table_temp_prefix = "tmp_"

    if input.instance_of?(String) then

      # Set the input document attribute
      @input_document = REXML::Document.new(input)

      # Retrieve all of the handler info values and store them in a hash variable named @info_values.
      REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
        @info_values[item.attributes["name"]] = item.text.to_s.strip
      end

      # Retrieve all of the handler parameters and store them in a hash variable named @parameters.
      REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
        @parameters[item.attributes["name"]] = item.text.to_s.strip
      end

      @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                              @info_values['enable_debug_logging'].downcase == 'true'
      puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging

    elsif input.instance_of?(Hash) then

      @info_values['host']              = input['host']
      @info_values['port']              = input['port']
      @info_values['jdbc_database_id']  = input['jdbc_database_id']
      @info_values['database_name']     = input['database_name']
      @info_values['user']              = input['user']
      @info_values['password']          = input['password']
      @info_values['max_connections']   = input['max_connections']
      @info_values['pool_timeout']      = input['pool_timeout']
      @enable_debug_logging             = input['enable_debug_logging'].to_s.downcase == 'yes' || input['enable_debug_logging'].to_s == 'true'
      puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging

      @info_values['api_username']    = input['api_username']
      @info_values['api_password']    = input['api_password']
      @info_values['api_server']      = input['api_server']
      @info_values['first_bulk_load'] = input['first_bulk_load'].to_s.strip.downcase == "yes" ? true : false
      @info_values['ignore_updates']  = input['ignore_updates'].to_s.strip.downcase == "yes" ? true : false

    end

    host            = @info_values["host"]
    port            = @info_values["port"]
    database_name   = @info_values["database_name"]
    user            = @info_values["user"]
    password        = @info_values["password"]

    max_connections = 1
    if @info_values['max_connections'].to_s =~ /\A[1-9]\d*\z/ then
      max_connections = @info_values["max_connections"].to_i
    end

    pool_timeout = 10
    if @info_values['pool_timeout'].to_s =~ /\A[1-9]\d*\z/ then
      pool_timeout = @info_values["pool_timeout"].to_i
    end

    # Attempt to connect to the database
    if @info_values["jdbc_database_id"].downcase == "sqlserver"
      @db = Sequel.connect("jdbc:#{@info_values["jdbc_database_id"]}://#{host}:#{port};database=#{database_name};user=#{user};password=#{password}", :max_connections => max_connections, :pool_timeout => pool_timeout)
      @db.extension :identifier_mangling
      @db.identifier_input_method = nil
      @db.identifier_output_method = nil
      @max_db_identifier_size = 128
      @table_temp_prefix.prepend("#")
      #@db.transaction_isolation_level = :serializable
      #@db.transaction_isolation_level = :repeatable
      #@db.transaction_isolation_level = :committed
    elsif @info_values["jdbc_database_id"].downcase == "oracle"
      @db = Sequel.connect("jdbc:#{@info_values["jdbc_database_id"]}:thin:#{user}/#{password}@#{host}:#{port}:#{database_name}", :max_connections => max_connections, :pool_timeout => pool_timeout)
      @db.extension :identifier_mangling
      @db.identifier_input_method = nil
      @db.identifier_output_method = nil
      @max_db_identifier_size = 30
    else
      @max_db_identifier_size = 64 if @info_values["jdbc_database_id"].downcase == "postgresql"
      @db = Sequel.connect("jdbc:#{@info_values["jdbc_database_id"]}://#{host}:#{port}/#{database_name}?user=#{user}&password=#{password}", :max_connections => max_connections, :pool_timeout => pool_timeout)
    end
    @db.logger = Logger.new($stdout) if @enable_debug_logging

    #Set max db identifier if info value is set to a valid positive integer.
    @max_db_identifier_size = @info_values["database_identifier_size"].strip.to_i if @info_values["database_identifier_size"].to_s.strip =~ /\A[1-9]\d*\z/
    #Decrement by 1 - used for string position truncating.
    @max_db_identifier_size -= 1

  end

#######################################################################################################
#
# execute
#
# The execute method gets called by the task engine when the handler's node is processed. It is
# responsible for performing whatever action the name indicates.
# If it returns a result, it will be in a special XML format that the task engine expects. These
# results will then be available to subsequent tasks in the process.
#
#######################################################################################################
  def execute(driver_parameters = nil)
    space_slug = get_param(@parameters, driver_parameters)["space_slug"].empty? ? @info_values["space_slug"] : get_param(@parameters, driver_parameters)["space_slug"]
    if @info_values['api_server'].include?("${space}")
      api_server = @info_values['api_server'].gsub("${space}", space_slug)
    elsif !space_slug.to_s.empty?
      api_server = @info_values['api_server']+"/"+space_slug
    else
      api_server = @info_values['api_server']
    end

    @error_handling = get_param(@parameters, driver_parameters)["error_handling"]

    if @info_values["api_username"].nil? == false then
      api_username    = URI.encode(@info_values["api_username"])
      api_password    = @info_values["api_password"]
    end

    submission_id     = get_param(@parameters, driver_parameters)["submission_id"]
    kapp_slug         = get_param(@parameters, driver_parameters)["kapp_slug"]
    form_slug         = get_param(@parameters, driver_parameters)["form_slug"]
    submission_delete = get_param(@parameters, driver_parameters)["submission_deletion_timestamp"]
    submission        = get_param(@parameters, driver_parameters)["submission_json"]
    submissions       = get_param(@parameters, driver_parameters)["submissions"]
    skip_table_create = get_param(@parameters, driver_parameters)["skip_table_create"].to_s.strip.downcase

    error_message = nil
    error_backtrace = nil
    submission_database_id = nil

    if submission.nil? == false then
      puts submission.inspect if @enable_debug_logging
    end

    form_table_name     = get_form_table_name(kapp_slug, form_slug)
    kapp_table_name     = get_kapp_table_name(kapp_slug)
    tmp_form_table_name = get_form_table_name(kapp_slug, form_slug, {:is_temporary => true})
    tmp_kapp_table_name = get_kapp_table_name(kapp_slug, {:is_temporary => true})

    puts "submissions: #{submissions.inspect}" if @enable_debug_logging

    # If this is a bulk insert...
    if submissions.nil? == false then

      puts "Starting bulk insert of #{submissions.size} submissions..." if @enable_debug_logging

      submission_field_names = get_param(@parameters, driver_parameters)['field_names']

      kapp_columns = [
        :c_anonymous,
        :c_closedAt,
        :c_closedBy,
        :c_coreState,
        :c_createdAt,
        :c_createdBy,
        :c_formSlug,
        :c_id,
        :c_originId,
        :c_parentId,
        :c_submittedAt,
        :c_submittedBy,
        :c_type,
        :c_updatedAt,
        :c_updatedBy,
      ]
      @kapp_fields.each do |field|
        kapp_columns.push(get_field_column_name(:unlimited => true, :field => field).to_sym)
        kapp_columns.push(get_field_column_name(:unlimited => false, :field => field).to_sym)
      end

      form_columns = [
        :c_anonymous,
        :c_closedAt,
        :c_closedBy,
        :c_coreState,
        :c_createdAt,
        :c_createdBy,
        :c_id,
        :c_originId,
        :c_parentId,
        :c_submittedAt,
        :c_submittedBy,
        :c_type,
        :c_updatedAt,
        :c_updatedBy,
      ]

      # value.to_s is necessary for attachment and multi-value answers which are not stored as JSON strings
      submission_field_names.each do |field|
        form_columns.push(get_field_column_name(:unlimited => true, :field => field).to_sym)
        form_columns.push(get_field_column_name(:unlimited => false, :field => field).to_sym)
      end

      new_kapp_submissions = []
      new_form_submissions = []

      submissions.each do |this_submission|
        kapp_submission = []
        form_submission = []

        closedAt    = this_submission['closedAt'].nil? ? nil : DateTime.parse(this_submission['closedAt'])
        createdAt   = this_submission['createdAt'].nil? ? nil : DateTime.parse(this_submission['createdAt'])
        submittedAt = this_submission['submittedAt'].nil? ? nil : DateTime.parse(this_submission['submittedAt'])
        updatedAt   = this_submission['updatedAt'].nil? ? nil : DateTime.parse(this_submission['updatedAt'])

        # Push submission information into a kapp submisison array.
        #
        # ORDER MUST MATCH kapp_columns ORDER !!
        #

        originId = nil
        parentId = nil
        if (this_submission['origin'].nil? == false && this_submission['origin'].has_key?('id')) then
          originId = this_submission['origin']['id']
        end
        if (this_submission['parent'].nil? == false && this_submission['parent'].has_key?('id')) then
          parentId = this_submission['parent']['id']
        end

        kapp_submission.push(this_submission['sessionToken'])
        kapp_submission.push(closedAt)
        kapp_submission.push(this_submission['closedBy'])
        kapp_submission.push(this_submission['coreState'])
        kapp_submission.push(createdAt)
        kapp_submission.push(this_submission['createdBy'])
        kapp_submission.push(this_submission['form']['slug'])
        kapp_submission.push(this_submission['id'])
        kapp_submission.push(originId)
        kapp_submission.push(parentId)
        kapp_submission.push(submittedAt)
        kapp_submission.push(this_submission['submittedBy'])
        kapp_submission.push(this_submission['type'])
        kapp_submission.push(updatedAt)
        kapp_submission.push(this_submission['updatedBy'])
        @kapp_fields.each do |field|
          kapp_submission.push(this_submission['values'][field])
          kapp_submission.push(this_submission['values'][field])
        end

        # Push submission information into a form submisison array.
        #
        # ORDER MUST MATCH form_columns ORDER !!
        #
        form_submission.push(this_submission['sessionToken'])
        form_submission.push(closedAt)
        form_submission.push(this_submission['closedBy'])
        form_submission.push(this_submission['coreState'])
        form_submission.push(createdAt)
        form_submission.push(this_submission['createdBy'])
        form_submission.push(this_submission['id'])
        form_submission.push(originId)
        form_submission.push(parentId)
        form_submission.push(submittedAt)
        form_submission.push(this_submission['submittedBy'])
        form_submission.push(this_submission['type'])
        form_submission.push(updatedAt)
        form_submission.push(this_submission['updatedBy'])
        submission_field_names.each do |field|
          field_value_unlimited = this_submission['values'][field].nil? ? nil : this_submission['values'][field].to_s
          field_value_limited   = this_submission['values'][field].nil? ? nil : this_submission['values'][field].to_s[0..@db_column_size_limits[:formField]]
          form_submission.push(field_value_unlimited)
          form_submission.push(field_value_limited)
        end

        new_kapp_submissions.push(kapp_submission)
        new_form_submissions.push(form_submission)
      end

      # Delete all records in the temporary tables.
      #
      # This is not safe for concurrency.
      #
      @db[tmp_kapp_table_name.to_sym].delete
      @db[tmp_form_table_name.to_sym].delete

      # Import records into the temporary kapp table
      @db[tmp_kapp_table_name.to_sym].import(
        kapp_columns,
        new_kapp_submissions
      )
      # Import records into the temporary form table
      @db[tmp_form_table_name.to_sym].import(
        form_columns,
        new_form_submissions
      )

      # Import all records from temp kapp table into the real kapp table, excluding records where the c_id is already in the main kapp table
      @db[kapp_table_name.to_sym].import(
        kapp_columns,
        @db[Sequel.as(tmp_kapp_table_name.to_sym, :tmp_kapp)].select{
          kapp_columns.map {|col| Sequel[:tmp_kapp][col]}
        }.left_outer_join(
          Sequel.as(kapp_table_name.to_sym, :kapp), :c_id => :c_id
        ).where(Sequel[:kapp][:c_id] => nil)
      )

      # Import all records from temp form table into the real form table, excluding records where the c_id is already in the form table
      @db[form_table_name.to_sym].import(
        form_columns,
        @db[Sequel.as(tmp_form_table_name.to_sym, :tmp_form)].select{
          form_columns.map {|col| Sequel[:tmp_form][col]}
        }.left_outer_join(
          Sequel.as(form_table_name.to_sym, :form), :c_id => :c_id
        ).where(Sequel[:form][:c_id] => nil)
      )

    else

      db_column_size_limits = @db_column_size_limits
      kapp_fields = @kapp_fields

      # If this is a deleted submission...
      if submission_delete.to_s.strip.size > 1 then

        ce_submission = {
          :c_id => submission["id"],
          :c_deletedAt => DateTime.parse(submission_delete)
        }

        # for both the kapp & form table...
        [kapp_table_name.to_sym, form_table_name.to_sym].each do |table_name|
          # if the record does *not* exist in the table
          if @db[table_name].select(:c_id).where(:c_id => submission["id"]).count == 0 then
            @db[table_name].insert(ce_submission)
          # else, update it.
          else
            @db[table_name].where(
              Sequel.lit('"c_id" = ?', submission['id']
            )).update(ce_submission) unless @info_values['ignore_updates']
          end
        end

      # If this is *not* a deleted submission...
      else

        #If passed in a submission id by the task engine, retireve the submission information.
        if submission_id.nil? == false then
          api_route = "#{api_server}/app/api/v1/submissions/#{submission_id}/?include=details,descendents,form,form.details,form.fields.details,type,form.kapp,values"
          puts "API ROUTE: #{api_route}" if @enable_debug_logging
          resource = RestClient::Resource.new(api_route, { :user => api_username, :password => api_password })
          response = resource.get
          submission = JSON.parse(response)['submission']
          submission_values = submission['values']
          form_definition = submission['form']
        else
          submission_values = submission['values']
          form_definition = submission['form']
        end

        unlimited_column_names_by_field, limited_column_names_by_field = get_column_names(submission_values)

        if skip_table_create != "yes" then
          generate_column_def_table()
          generate_table_def_table()
          create_or_update_form_table({
            :form_slug => form_slug,
            :kapp_slug => kapp_slug,
            :submission => submission
          })
          generate_kapp_table(
            get_kapp_table_name(kapp_slug)
          )

          insert_table_definition({
            :form_slug => form_slug,
            :kapp_slug => kapp_slug,
            :form_table_name => form_table_name,
            :submission => submission,
            :form_definition => form_definition
          })
        end

        puts "Submission values: (#{submission_values.inspect})" if @enable_debug_logging

        originId = nil
        parentId = nil
        if (submission['origin'].nil? == false && submission['origin'].has_key?('id')) then
          originId = submission['origin']['id']
        end
        if (submission['parent'].nil? == false && submission['parent'].has_key?('id')) then
          parentId = submission['parent']['id']
        end

        #Kapp general submission DB transaction.
        @db.transaction(:retry_on => [Sequel::SerializationFailure]) do

          ce_submission = {
            :c_id => submission['id'],
            :c_formSlug => form_slug,
            :c_anonymous => submission['sessionToken'],
            :c_closedBy => submission['closedBy'],
            :c_coreState => submission['coreState'],
            :c_createdBy => submission['createdBy'],
            :c_originId => submission['origin']['id'],
            :c_parentId => submission['parent']['id'],
            :c_submittedBy => submission['submittedBy'],
            :c_updatedBy => submission['updatedBy'],
            :c_type => submission['type'],
          }
          kapp_fields.each do |field|
            unlimited_field = get_field_column_name(:unlimited => true, :field => field).to_sym
            limited_field = get_field_column_name(:unlimited => false, :field => field).to_sym
            limited_value = submission['values'][field].nil? ? nil : submission['values'][field][0..db_column_size_limits[:formField]]
            ce_submission[unlimited_field] = submission['values'][field]
            ce_submission[limited_field] = limited_value
          end

          #only set the datetime values if they're not null, and set them as a proper datetime object.
          ["closedAt", "createdAt", "submittedAt", "updatedAt"].each do |actionTimestamp|
            ce_submission["c_#{actionTimestamp}".to_sym] = DateTime.parse(submission[actionTimestamp]) if submission[actionTimestamp].nil? == false
          end

          # if the record does not exist in the database, insert it.
          if @info_values['first_bulk_load'] || @db[kapp_table_name.to_sym].select(:c_id).where(:c_id => submission["id"]).count == 0 then
            @db[kapp_table_name.to_sym].insert(ce_submission)
          # else, update it.
          else
            @db[kapp_table_name.to_sym].where(
              Sequel.lit('"c_id" = ? and "c_updatedAt" < ?', submission['id'], ce_submission[:c_updatedAt]
            )).update(ce_submission) unless @info_values['ignore_updates']
          end

        #end general kapp submission database transaction
        end

        puts "Submission values: (#{submission_values.inspect})" if @enable_debug_logging

        #Form submission DB transaction.
        @db.transaction(:retry_on => [Sequel::SerializationFailure]) do

          # Once the table has been created/modified/verified, insert the submission into the table
          form_db_submission = {
            :c_id => submission["id"],
            :c_originId => submission["origin"]["id"],
            :c_parentId => submission["parent"]["id"],
            :c_anonymous => submission['sessionToken'],
            :c_closedBy => submission["closedBy"],
            :c_coreState => submission["coreState"],
            :c_createdBy => submission["createdBy"],
            :c_submittedBy => submission["submittedBy"],
            :c_updatedBy => submission["updatedBy"]
          }

          # only set the datetime values if they're not null, and set them as a proper datetime object.
          ["closedAt", "createdAt", "submittedAt", "updatedAt"].each do |actionTimestamp|
            form_db_submission["c_#{actionTimestamp}".to_sym] = DateTime.parse(submission[actionTimestamp]) if submission[actionTimestamp].nil? == false
          end

          # value.to_s is necessary for attachment and multi-value answers which are not stored as JSON strings
          submission_values.each { |field,value|
            #ternary: if value is nil, use nil - else use the value converted to a string.
            form_db_submission[unlimited_column_names_by_field[field].to_sym] = value.nil? ? nil : value.to_s
            form_db_submission[limited_column_names_by_field[field].to_sym] = value.nil? ? nil : value.to_s[0,db_column_size_limits[:formField]]
          }

          puts "Inserting the submission '#{submission["id"]}'" if @enable_debug_logging
          db_submissions = @db[form_table_name.to_sym]
          if @info_values['first_bulk_load'] || db_submissions.select(:c_id).where(:c_id => submission["id"]).count == 0 then
            submission_database_id = db_submissions.insert(form_db_submission)
          else
            submission_database_id = db_submissions.where(Sequel.lit('"c_id" = ? and "c_updatedAt" < ?', submission['id'], form_db_submission[:c_updatedAt])).update(form_db_submission)  unless @info_values['ignore_updates']
          end
        #end form submission database transaction
        end
      #end statement for else statement for if this is a delete submission update.
      end
    #end statement for else statement for if this is a bulk submission insert.
    end

    rescue Exception => e
      if @error_handling == "Error Message"
        error_message = e.message
        error_backtrace = e.backtrace.join("\r\n")
        return get_handler_xml_results({
          "Handler Error Message" => error_message,
          "Handler Error Backtrace" => error_backtrace
        })
      else
        raise e
      end

    ensure
      # Disconnect at the end *if* running through the Task engine.
      @db.disconnect if driver_parameters.nil? == true
      puts "Disconnecting from database." if driver_parameters.nil? == true

  end

#######################################################################################################
#
# disconnect_db
#
# Disconnects the database connection. This is only used externally to this file as the @db instance variable
# is not exposed publicly.
#
#######################################################################################################
  def disconnect_db
    @db.disconnect
  end

##########################################################################################################
#
# get_field_column_name
#
# Returns a column name for a field name on a form. Handles scenarios for when a field name is loner than
# what column lengths support and prefixes the column name with a u or an l to indicate if it is an unlimited
# length column or a limited length column.
#
##########################################################################################################

  def get_field_column_name(args)
    #expected args => :unlimited, :field
    prefix = args[:unlimited] ? "u_" : "l_"
    field_id = "_#{args[:field_id]}"
    field_name = args[:field]
    column_name = "#{prefix}#{field_name}"
    checksum = "_#{Digest::CRC16.hexdigest(field_name)}"
    field_truncate_pos = @max_db_identifier_size - (prefix.size + checksum.size)
    if column_name.size > @max_db_identifier_size then
      "#{prefix}#{field_name[0,field_truncate_pos]}#{checksum}"
    else
      column_name
    end
  end

##########################################################################################################
#
# get_form_table_name
#
# Returns a form table name for a form based on kapp slug and form slug. Handles temporary tables & checks if a CRC16 checksum is necessary to append
#
##########################################################################################################

  def get_form_table_name(kapp_slug, form_slug, options = {})
    form_table_name = "#{kapp_slug}_#{form_slug}"
    form_table_name.prepend(@table_temp_prefix) if options[:is_temporary]
    checksum = "_#{Digest::CRC16.hexdigest(form_table_name)}"
    truncate_pos = @max_db_identifier_size - checksum.size
    if form_table_name.size > @max_db_identifier_size then
      new_table_name = "#{form_table_name[0,truncate_pos]}#{checksum}"
    else
      new_table_name = form_table_name
    end

    puts "Form table name: #{new_table_name}" if @enable_debug_logging

    new_table_name

  end

##########################################################################################################
#
# get_kapp_table_name
#
# Returns a kapp table name for a kapp slug. Handles temporary tables & checks if a CRC16 checksum is necessary to append
#
##########################################################################################################

  def get_kapp_table_name(kapp_slug, options = {})
    kapp_table_name = "#{kapp_slug}"
    kapp_table_name.prepend(@table_temp_prefix) if options[:is_temporary]
    checksum = "_#{Digest::CRC16.hexdigest(kapp_table_name)}"
    truncate_pos = @max_db_identifier_size - checksum.size
    if kapp_table_name.size > @max_db_identifier_size then
      new_table_name = "#{kapp_table_name[0,truncate_pos]}#{checksum}"
    else
      new_table_name = kapp_table_name
    end

    puts "Kapp table name: #{new_table_name}" if @enable_debug_logging

    new_table_name

  end

##########################################################################################################
#
# generate_column_def_table
#
# generates the column definition table. This table helps map form fields to their column names in form tables.
# Useful for columns that have to use a CRC16 checksum to shorten their column name.
#
##########################################################################################################

  def generate_column_def_table()
    table_def_name = "column_definitions"
    # If the table doesn't already exist, create it
    puts "Column definition table (#{table_def_name}) doesn't exist. Creating new definition table." if @enable_debug_logging
    db_column_size_limits = @db_column_size_limits
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      @db.create_table?(table_def_name.to_sym) do
        String :tableName, :size => db_column_size_limits[:tableName]
        String :kappSlug, :size => db_column_size_limits[:kappSlug]
        String :formSlug, :size => db_column_size_limits[:formSlug]
        String :fieldName, :text => true
        String :fieldKey, :size => db_column_size_limits[:fieldKey]
        String :columnName, :size => db_column_size_limits[:columnName]
        primary_key [:tableName, :columnName]
      end
    end
  end

##########################################################################################################
#
# generate_table_def_table
#
# generates the table definition table. This table helps map forms to their table names.
# Useful for tables that have to use a CRC16 checksum to shorten their table name.
#
##########################################################################################################

  def generate_table_def_table()
    table_def_name = "table_definitions"

    # If the table doesn't already exist, create it
    puts "Creating table definition table (#{table_def_name}) if it doesn't exist." if @enable_debug_logging
    db_column_size_limits = @db_column_size_limits
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      @db.create_table?(table_def_name.to_sym) do
        String :tableName, :primary_key => true, :size => 128
        String :kappSlug, :size => db_column_size_limits[:kappSlug]
        String :formSlug, :size => db_column_size_limits[:formSlug]
        String :formName, :size => db_column_size_limits[:formName]
      end
    end
  end

##########################################################################################################
#
# insert_column_definition
#
# Insert a record into a column definition table for defining a new form field column being adding to a form table.
# This helps map a full length field name to a column name in a form table.
#
##########################################################################################################

  def insert_column_definition(args)

    submission_database_id = nil
    submission = args[:submission]
    column_name = args[:column_name]
    ce_field = args[:ce_field]
    form_table_name = args[:form_table_name]
    kapp_slug = args[:kapp_slug]
    form_slug = args[:form_slug]

    field_id_lookup = {}
    submission['form']['fields'].each do |field|
      id = field['key']
      name = field['name']
      field_id_lookup[name] = id
    end

    table_def_name = "column_definitions"

    #Table definition generation.
    # Once the table has been created/modified/verified, insert the submission into the table
    db_submission = {
      :tableName => form_table_name,
      :kappSlug => kapp_slug,
      :formSlug => form_slug,
      :fieldName => ce_field,
      :fieldKey => field_id_lookup[ce_field],
      :columnName => column_name
    }

    puts "Inserting the column definition for the column name '#{column_name}'" if @enable_debug_logging
    db_submissions = @db[table_def_name.to_sym]
    #if db_submissions.select(:tableName).where(:tableName => form_table_name, :columnName => column_name).for_update.first.nil? then
    if db_submissions.select(:tableName).where(:tableName => form_table_name, :columnName => column_name).count == 0 then
      submission_database_id = db_submissions.insert(db_submission)
    else
      submission_database_id = db_submissions.where(:tableName => form_table_name, :columnName => column_name).update(db_submission) unless @info_values['ignore_updates']
    end

    submission_database_id

  end

##########################################################################################################
#
# insert_table_definition
#
# Insert a record into a table definition for defining a new table being created in the database. Includes full form name and slug.
#
##########################################################################################################

  def insert_table_definition(args)

    submission_database_id = nil
    submission = args[:submission]
    form_definition = args[:form_definition]
    form_table_name = args[:form_table_name]
    kapp_slug = args[:kapp_slug]
    form_slug = args[:form_slug]

    table_def_name = "table_definitions"

    #Table definition generation.
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do

      # Once the table has been created/modified/verified, insert the submission into the table
      db_submission = {
        :tableName => form_table_name,
        :kappSlug => kapp_slug,
        :formSlug => form_slug,
        :formName => form_definition['name']
      }

      puts "Inserting the table definition for the table '#{form_table_name}' into '#{table_def_name}'" if @enable_debug_logging
        db_submissions = @db[table_def_name.to_sym]
        if db_submissions.select(:tableName).where(:tableName => form_table_name).count == 0 then
          submission_database_id = db_submissions.insert(db_submission)
        else
          submission_database_id = db_submissions.where(:tableName => form_table_name).update(db_submission) unless @info_values['ignore_updates']
        end
    end

    submission_database_id

  end

##########################################################################################################
#
# update_form_table_columns?
#
# Updates the form table with new columns, based on submission values, if they do not already exist on the table.
#
##########################################################################################################

  def update_form_table_columns?(args)

    submission        = args[:submission]
    kapp_slug         = args[:kapp_slug]
    form_slug         = args[:form_slug]
    submission_values = submission['values']
    unlimited_column_names_by_field, limited_column_names_by_field = get_column_names(submission_values)

    form_table_name = get_form_table_name(kapp_slug, form_slug, {:is_temporary => args[:is_temporary]})

    # If the table exists, check to see if the submission values match up with
    # the table columns. If a column doesn't exist, add it
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      columns = get_table_column_names(form_table_name.to_sym)
      columns_to_add = []
      column_to_field_name = {}

      submission_values.each do |field,value|
        sql_column_unlimited = unlimited_column_names_by_field[field]
        sql_column_limited = limited_column_names_by_field[field]
        columns_to_add.push(sql_column_unlimited) if !columns.include?(sql_column_unlimited.to_sym)
        columns_to_add.push(sql_column_limited) if !columns.include?(sql_column_limited.to_sym)
        column_to_field_name[sql_column_limited] = field
        column_to_field_name[sql_column_unlimited] = field
      end
      if columns_to_add.empty? == false
        puts "Adding the new columns '#{columns_to_add.join(",")}' to #{form_table_name}" if @enable_debug_logging
        @db.alter_table(form_table_name.to_sym) do
          columns_to_add.each { |sql_column| add_column(sql_column.to_sym, String, :text => true) }
        end
        columns_to_add.each { |sql_column|
          insert_column_definition({
            :form_slug => form_slug,
            :kapp_slug => kapp_slug,
            :submission => submission,
            :form_table_name => form_table_name,
            :ce_field => column_to_field_name[sql_column],
            :column_name => sql_column
          })
        }
      end
    end

  end

##########################################################################################################
#
# generate_kapp_table
#
# Creates the kapp table if it does not already exist.
#
##########################################################################################################

  def generate_kapp_table(kapp_slug, opt_args = {})
    # If the table doesn't already exist, create it
    db_table_name = get_kapp_table_name(kapp_slug, {:is_temporary => opt_args[:is_temporary]})
    db_options = {}
    db_options[:temp] = true if opt_args[:is_temporary]
    db_options[:on_commit_preserve_rows] = true if opt_args[:is_temporary] && @info_values["jdbc_database_id"].downcase == "oracle"

    db_column_size_limits = @db_column_size_limits
    kapp_fields = @kapp_fields
    kapp_unlimited_column_name = {}
    kapp_limited_column_name = {}
    kapp_fields.each do |field|
      kapp_unlimited_column_name[field] = get_field_column_name(:unlimited => true, :field => field)
      kapp_limited_column_name[field] = get_field_column_name(:unlimited => false, :field => field)
    end
    puts "Creating Kapp table (#{db_table_name}) if it doesn't exist."
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      @db.create_table?(db_table_name.to_sym, db_options) do
        String :c_id, :primary_key => true, :size => db_column_size_limits[:id]
        String :c_originId, :size => db_column_size_limits[:originId]
        String :c_parentId, :size => db_column_size_limits[:parentId]
        String :c_formSlug, :size => db_column_size_limits[:formSlug]
        String :c_anonymous, :size => db_column_size_limits[:anonymous]
        DateTime :c_closedAt
        String :c_closedBy, :size => db_column_size_limits[:closedBy], :unicode => true
        String :c_coreState, :size => db_column_size_limits[:coreState]
        DateTime :c_createdAt
        String :c_createdBy, :size => db_column_size_limits[:createdBy], :unicode => true
        DateTime :c_deletedAt
        DateTime :c_submittedAt
        String :c_submittedBy, :size => db_column_size_limits[:submittedBy], :unicode => true
        DateTime :c_updatedAt
        String :c_updatedBy, :size => db_column_size_limits[:updatedBy], :unicode => true
        String :c_type, :size => db_column_size_limits[:type]
        kapp_fields.each do |field|
          send("String",kapp_unlimited_column_name[field], :text => true, :unicode => true)
          send("String",kapp_limited_column_name[field], :text => true, :unicode => true, :size => db_column_size_limits[:formField])
        end
      end
    end
  end

##########################################################################################################
#
# generate_form_table
#
# Generates the form table and creates column definition records for every field on the form (for both the limited and unlimited length columns)
#
##########################################################################################################

  def generate_form_table(args)
    form_table_name = get_form_table_name(
      args[:kapp_slug],
      args[:form_slug],
      {:is_temporary => args[:is_temporary]}
    )
    submission = args[:submission]
    unlimited_column_names_by_field, limited_column_names_by_field = get_column_names(submission['values'])
    db_options = {}
    db_options[:temp]                    = true if args[:is_temporary]
    db_options[:on_commit_preserve_rows] = true if args[:is_temporary] && @info_values["jdbc_database_id"].downcase == "oracle"

    db_column_size_limits = @db_column_size_limits
    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      # If the table doesn't already exist, create it
      puts "Creating Form table (#{form_table_name}) if it doesn't exist."
      @db.create_table?(form_table_name.to_sym, db_options) do
        String :c_id, :primary_key => true, :size => db_column_size_limits[:id]
        String :c_originId, :size => db_column_size_limits[:originId]
        String :c_parentId, :size => db_column_size_limits[:parentId]
        String :c_anonymous, :size => db_column_size_limits[:anonymous]
        DateTime :c_closedAt
        String :c_closedBy, :size => db_column_size_limits[:closedBy], :unicode => true
        String :c_coreState, :size => db_column_size_limits[:coreState]
        DateTime :c_createdAt
        String :c_createdBy, :size => db_column_size_limits[:createdBy], :unicode => true
        DateTime :c_deletedAt
        DateTime :c_submittedAt
        String :c_submittedBy, :size => db_column_size_limits[:submittedBy], :unicode => true
        String :c_type, :size => db_column_size_limits[:type], :unicode => true
        DateTime :c_updatedAt
        String :c_updatedBy, :size => db_column_size_limits[:updatedBy], :unicode => true
        submission['values'].each do |field,value|
          send("String",unlimited_column_names_by_field[field].to_sym, :text => true, :unicode => true)
          send("String",limited_column_names_by_field[field].to_sym, :text => true, :unicode => true, :size => db_column_size_limits[:formField])
        end
      end
    end

    @db.transaction(:retry_on => [Sequel::SerializationFailure]) do
      submission['values'].each do |field,value|
        insert_column_definition({
          :submission => submission,
          :form_slug => args[:form_slug],
          :kapp_slug => args[:kapp_slug],
          :form_table_name => form_table_name,
          :ce_field => field,
          :column_name => unlimited_column_names_by_field[field]
        })
        insert_column_definition({
          :submission => submission,
          :form_slug => args[:form_slug],
          :kapp_slug => args[:kapp_slug],
          :form_table_name => form_table_name,
          :ce_field => field,
          :column_name => limited_column_names_by_field[field]
        })
      end
    end

  end

##########################################################################################################
#
# create_or_update_form_table
#
# either creates a form table along with adding a definition entry or updates the columns in the existing table
#
##########################################################################################################

  def create_or_update_form_table(args)
    form_table_name = get_form_table_name(
      args[:kapp_slug],
      args[:form_slug],
      {:is_temporary => args[:is_temporary]}
    )

    if @db.table_exists?(form_table_name.to_sym) == false then
      generate_form_table({
        :kapp_slug => args[:kapp_slug],
        :form_slug => args[:form_slug],
        :submission => args[:submission],
        :is_temporary => args[:is_temporary]
      })
      insert_table_definition({
        :kapp_slug => args[:kapp_slug],
        :form_slug => args[:form_slug],
        :form_table_name => form_table_name,
        :submission => args[:submission],
        :form_definition => args[:submission]['form']
      })
    else
      update_form_table_columns?({
        :submission => args[:submission],
        :kapp_slug => args[:kapp_slug],
        :form_slug => args[:form_slug],
        :is_temporary => args[:is_temporary]
      })
    end

  end

##########################################################################################################
#
# get_column_names returns table column names for form fields, both limited and unlimited length.
#
##########################################################################################################

  def get_column_names(submission_values)
    unlimited_column_names_by_field = {}
    limited_column_names_by_field = {}
    submission_values.each do |field,value|
      unlimited_column_names_by_field[field] = get_field_column_name(:unlimited => true, :field => field)
      limited_column_names_by_field[field] = get_field_column_name(:unlimited => false, :field => field)
    end
    return unlimited_column_names_by_field, limited_column_names_by_field
  end

##########################################################################################################
#
# get_table_column_names returns an array of the columns for a specified database table.
#
##########################################################################################################

  def get_table_column_names(table)
    @db[table].columns
  end

##########################################################################################################
#
# get_param returns either parameters or driver_parameters depending on which is not nil.
#
# used for distinguishing parameters passed in either by Task or the backfill script.
#
##########################################################################################################

  def get_param(parameters, driver_parameters)
    if driver_parameters.nil? == false then
      driver_parameters
    else
      parameters
    end
  end

##########################################################################################################
#
# get_handler_xml_results
#
# formats all of the inputs passed to XML for Kinetic Task output
#
##########################################################################################################

  def get_handler_xml_results(args = {})
    results = "<results>"
    args.each do |key,value|
      results << %|<result name="#{escape(key.to_s)}">#{escape(value.to_s)}</result>|
    end
    results << "</results>"
    return results
  end

##########################################################################################################
#
# escape
#
# This is a template method that is used to escape results values (returned in
# execute) that would cause the XML to be invalid.  This method is not
# necessary if values do not contain character that have special meaning in
# XML (&, ", <, and >), however it is a good practice to use it for all return
# variable results in case the value could include one of those characters in
# the future.  This method can be copied and reused between handlers.
#
##########################################################################################################
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
