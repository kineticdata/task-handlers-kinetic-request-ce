== Kinetic Request CE Form Update Attributes
Updates one or More Form Attributes in Kinetic Request CE for the specified space, kapp and (form).

Notice: For the "attributes" parameter in simple_input.rb, make sure
to put the JSON object within the single quotes.. example 'attributes' => '[{"name": "test","values": ["Acme"]}]'

=== Parameters
[Error Handling]
  Determine what to return if an error is encountered.  menu="Error Message,Raise Error"
[SpaceSlug]
  The Space slug to be searched. If this value is not entered, the
  Space slug will default to the one configured in info values.
[Kapp Slug]
    Slug of the Kapp to Search for Forms in
[Form Slug]
    If updating a single form's attributes, enter that form's slug here
    If updating all forms within a KAPP, leave this blank
[Attributes]
    A JSON array of the attributes to update / create. Ex. [{'name': 'Attribute Name','values': ['Attr Value 1']}]
[Create New]
	Values are 'true' or 'false'. If set to true, if an attribute doesn't exist on
    the form-slug provided, or all of the forms in the kapp (based on form slug parameter)
    the attributes provided in the attributes param will be added to each form selected.
    If set to false (default) the attribute will only be updated if it already exists on the form


=== Sample Configuration
Error Handling::          Error Message
Space Slug::              test-space
Kapp Slug::               test-kapp
Form Slug::               test-form OR leave blank
Attributes To Update::    [{"name": "test","values": ["Acme"]}]
Create New Attribute::    false

=== Results
[Handler Error Message]
  Error message if an error was encountered and Error Handling is set to "Error Message".

=== Detailed Description
This handler will update form attributes on one or more forms.
- If a form-slug is provided, the handler will only update that form
- If a form-slug is NOT provided, the handler will update ALL forms within the given Space / KAPP
- If the "Create New" parameter is set to 'true' for each form selected, the handler will search for
  the attribute and if it exists. If it exists, it will update it to the new value provided. If it doesn't
  exist, it will create the new attribtue value

