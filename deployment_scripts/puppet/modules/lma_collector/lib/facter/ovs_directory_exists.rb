Facter.add('ovs_log_directory') do
    setcode do
      File.directory? '/var/log/openvswitch'
    end
  end
