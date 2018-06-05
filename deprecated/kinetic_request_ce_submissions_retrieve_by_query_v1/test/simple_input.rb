{
  'info' => {
    'api_server' => 'https://localhost:8080/kinetic',
    'api_username' => 'user@kineticdata.com',
    'api_password' => 'password',
    'space_slug' => ''
  },
  'parameters' => {
    'space_slug' => '',
    'kapp_slug' => 'admin',
    'form_slug' => 'group-membership',
    'includes' => 'details, values',
    'limit' => '1000',
    'query' => 'values[Group%20Id]=Test%20Group%201'   #Make sure to URI encode the query on input.
  }
}
