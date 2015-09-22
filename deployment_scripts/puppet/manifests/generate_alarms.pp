include heka::params

$lma = hiera_hash('lma')
$alarms_definitions = $lma['alarms']
$alarms_dir = $heka::params::lua_modules_dir

$cluster_names = get_cluster_names($lma, hiera('roles'))
validate_hash($cluster_names)

$cluster_alarms = get_cluster_alarms($lma, $cluster_names)
validate_hash($cluster_alarms)

define create_alarms (
    $type,
    $cluster_name,
    $logical_name,
    $alarms,
) {
    $lua_template = inline_template('
local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local alarms = {
<% @alarms.each do |alarm_name| -%>
<% @alarms_definitions.each do |alarm| -%>
<% if alarm_name == alarm["name"] -%>
  {
    name = \'<%= alarm_name %>\',
    description = \'<%= alarm["description"] %>\',
    severity = \'<%= alarm["severity"] %>\',
    trigger = {
<% if alarm["trigger"].key?("logical_operator") -%>
      logical_operator = \'<%= alarm["trigger"]["logical_operator"] %>\'
<% else -%>
      logical_operator = \'or\'
<% end -%>
      rules = {
<% alarm["trigger"]["rules"].each do |rule|  -%>
        metric = \'<%= rule["metric"] %>\',
<% if rule["fields"] -%>
        fields = <%= rule["fields"]  %>,
<% else -%>
        fields = {},
<% end -%>
        relational_operator = \'<%= rule["relational_operator"] %>\',
        threshold = \'<%= rule["threshold"] %>\',
        window = \'<%= rule["window"] %>\',
        period = \'<%= rule["period"] %>\',
        function = \'<%= rule["function"] %>\',
<% end -%>
      },
    },
  },
<% end -%>
<% end -%>
<% end -%>
}
')

    # Create lua structures that describes alarms
    file { "${alarms_dir}/lma_alarms_${name}.lua":
       ensure => present,
       content => inline_template($lua_template),
    }
}

create_resources(create_alarms, $cluster_alarms)
