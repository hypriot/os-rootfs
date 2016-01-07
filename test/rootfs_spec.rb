require 'serverspec'
set :backend, :exec

describe file('etc/hostname') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
end

describe file('bin/bash') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 755 }
end

describe file('etc/apt/sources.list') do
  it { should be_file }
  its(:content) { should contain /deb http:\/\/httpredir.debian.org\/debian jessie main/ }
  its(:content) { should contain /deb http:\/\/httpredir.debian.org\/debian jessie-updates main/ }
  its(:content) { should contain /deb http:\/\/security.debian.org\/ jessie\/updates main/ }
end

describe file('etc/systemd/network/eth0.network') do
  it { should be_file }
  its(:content) { should contain /Name=eth0/ }
  its(:content) { should contain /DHCP=yes/ }
end

describe file('etc/ssh/sshd_config') do
  it { should be_file }
  its(:content) { should contain /PermitRootLogin yes/ }
end

describe file('etc/locale.gen') do
  it { should be_file }
  its(:content) { should contain /en_US.UTF-8/ }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /HYPRIOT_/ }
end

describe file('/etc/hostname') do
  it { should be_file }
  its(:content) { should contain /black-pearl/ }
end

describe file('/etc/hostname') do
  it { should be_file }
  its(:content) { should contain /black-pearl/ }
end

describe file('/etc/shadow') do
  it { should be_file }
  its(:content) { should_not contain /root:*/ }
end
