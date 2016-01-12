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
  its(:content) { should contain 'deb http://httpredir.debian.org/debian jessie main' }
  its(:content) { should contain 'deb http://httpredir.debian.org/debian jessie-updates main' }
  its(:content) { should contain 'deb http://security.debian.org/ jessie/updates main' }
end

describe file('etc/systemd/network/eth0.network') do
  it { should be_file }
  its(:content) { should contain /Name=eth0/ }
  its(:content) { should contain /DHCP=yes/ }
end

describe file('etc/resolv.conf') do
  it { should be_symlink }
end

describe file('run/systemd/resolve/resolv.conf') do
  it { should be_file }
end

describe file('etc/ssh/sshd_config') do
  it { should be_file }
  its(:content) { should contain /^PermitRootLogin without-password/ }
end

describe file('etc/shadow') do
  it { should be_file }
  its(:content) { should contain /^root:\*:/ }
end

describe file('etc/locale.gen') do
  it { should be_file }
  its(:content) { should contain /en_US.UTF-8/ }
end

describe file('etc/hostname') do
  it { should be_file }
  its(:content) { should contain /^black-pearl$/ }
end

describe file('etc/group') do
  it { should be_file }
  its(:content) { should contain /^docker:x:.*:pirate/ }
  its(:content) { should contain /^pirate:x:/ }
end

describe file('etc/passwd') do
  it { should be_file }
  its(:content) { should contain /^pirate:/ }
end

describe file('etc/shadow') do
  it { should be_file }
  its(:content) { should contain /^pirate:/ }
end

describe file('etc/sudoers.d/user-pirate') do
  it { should be_file }
  it { should be_mode 440 }
  its(:content) { should contain /^pirate ALL=NOPASSWD: ALL$/ }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /HYPRIOT_OS=/ }
  its(:content) { should contain /HYPRIOT_TAG=/ }
end
