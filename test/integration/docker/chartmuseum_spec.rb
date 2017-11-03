# encoding: utf-8

control 'Chart packages created' do
  title 'Verify chartmuseum chart packages'
  desc 'Ensures chartmuseum creates chart packages'
  
  describe file("/datavols/helm/chart-repo/public") do
    it { should exist }
  end

  describe command("ls /datavols/helm/chart-repo/public") do
    its(:stdout) { should match /redmine/ }
    its(:stdout) { should match /mailhog/ }
  end
end